## This file is created to explain everything i did for Problem statement 1 and 3.
### For Problem statement 2 checkout : [Link](https://github.com/harshitrwt/assignment_devOps)
### Problem Statement 1 - Deploy Wisecow with TLS and CI/CD

I started by forking the Wisecow repository and cloning my fork locally.
Inside the repo I created a new branch called k8sdeployment where I kept all of my Kubernetes and CI changes.

The first task was to containerize the application.
I wrote a Dockerfile using debian:stable-slim as the base image.
Inside the image I installed the required runtime packages (cowsay, fortune-mod, fortune etc) and updated the PATH so that the fortune command could be found.
I copied the wisecow.sh script into the container, made it executable, exposed port 4499, and set the container’s CMD to run the script.

After building the image locally with
docker build -t wisecow:latest .
I ran a quick smoke test using
docker run --rm -p 4499:4499 wisecow:latest
and verified that I could reach the service over plain HTTP at http://localhost:4499.

Here's how it looked

<img width="1243" height="479" alt="Screenshot 2025-09-22 235442" src="https://github.com/user-attachments/assets/4d8fedde-d6f2-4536-b011-f34e1946e1ff" />


Once the container worked, I tagged and pushed it to my Docker Hub account so that a Kubernetes cluster could pull it

With the image available, I moved to Kubernetes.
Inside a new k8s folder I created three manifests:

deployment.yaml - defined a Deployment running the image harshitrwt009/wisecow:latest and exposing container port 4499.

service.yaml - defined a Service so that the deployment could be reached inside the cluster 

ingress.yaml - defined an Ingress to serve the application under the hostname wisecow.local and referenced a TLS secret.

I started a local Kubernetes cluster with
```
minikube start --driver=docker
```
and applied all the manifests using
```
kubectl apply -f k8s/.
```
After a few seconds I could reach the app again via
minikube service wisecow
and confirmed it was live over HTTP.

Kubernetes resources and the app running on HTTP.

<img width="1445" height="626" alt="Screenshot 2025-09-22 235406" src="https://github.com/user-attachments/assets/a1801335-e5a9-4aa7-a082-ea263d9c780a" />


To enable HTTPS locally I used self-signed certificates. I chose self-signed certificates because I was working entirely in a local development environment and I could not issue a real certificate from Let’s Encrypt without a public domain name.
Self-signed certificates allow full TLS encryption for development and testing, and tools like mkcert make the process quick. 

***Before adding the certificate the URL looked like this***

<img width="1283" height="541" alt="Screenshot 2025-09-24 011416" src="https://github.com/user-attachments/assets/834a6d5e-00d2-49d5-9b18-9c7337f79bb7" />

Then 
Inside WSL I installed mkcert and ran
```
mkcert -install
```

to create a local certificate authority.
Then I generated a certificate for my hostname with
mkcert wisecow.local
which produced wisecow.local.pem and wisecow.local-key.pem.
I created the Kubernetes TLS secret with
```
kubectl create secret tls wisecow-tls --cert=wisecow.local.pem --key=wisecow.local-key.pem
```
and applied my Ingress again.

Because my browser was running on Windows while mkcert was inside WSL, I also needed to trust the certificate on Windows.
I copied the root CA file from WSL using
```
mkcert -CAROOT
```
to find it and then copied the **rootCA.pem** file to Windows.
From an administrator PowerShell I ran
```
certutil -addstore "Root" rootCA.pem
```

to add the mkcert root CA to the Windows Trusted Root Certification Authorities store.
Finally I edited the Windows hosts file
C:\Windows\System32\drivers\etc\hosts
to map my Minikube IP (or 127.0.0.1) to **wisecow.local.**
After restarting the browser I could open
https://wisecow.local
and see the padlock showing that TLS was working.

***Browser showing HTTPS with the self-signed certificate.***

<img width="942" height="495" alt="Screenshot 2025-09-24 014932" src="https://github.com/user-attachments/assets/b3371c8e-9472-4bf5-9c01-7dab2859cfe4" />

<img width="942" height="495" alt="Screenshot 2025-09-24 014939" src="https://github.com/user-attachments/assets/8ad2889c-9cdb-4f94-bc98-38accef707ad" />

---

For continuous integration I added a workflow file
**.github/workflows/dockerpush.yaml.**
The workflow runs on every push to my branch, logs in to Docker Hub using repository secrets, builds the Docker image, and pushes the new latest tag.
When I make code changes and push them, the GitHub Action automatically rebuilds the image.

<img width="891" height="612" alt="Screenshot 2025-09-25 001706" src="https://github.com/user-attachments/assets/8942f87c-6eb5-499a-ba41-c66497aaa870" />

---

## Problem Statement 3 – Zero-Trust KubeArmor Policy

After completing the main deployment I attempted the optional zero-trust policy using KubeArmor.


I installed KubeArmor in the Minikube cluster using Helm and confirmed that the pods (kubearmor-controller, kubearmor-relay, etc.) were running.

<img width="909" height="169" alt="Screenshot 2025-09-24 165340" src="https://github.com/user-attachments/assets/ade1dbc0-a62e-4493-8f44-07b62ddaaabc" />

I then wrote a simple KubeArmorPolicy in Audit mode that targeted the Wisecow pod and tried to watch for shell executions.
I applied it successfully and could see policy detection logs with
```
kubectl -n kubearmor logs -l kubearmor-app=kubearmor -f.
```
<img width="1832" height="435" alt="Screenshot 2025-09-24 165422" src="https://github.com/user-attachments/assets/d7e54ef4-886c-4f61-a30b-2105169f3e7a" />

However, because my Minikube cluster was running with the **Docker driver on WSL2**, the underlying kernel did not provide the AppArmor/SELinux hooks that KubeArmor needs to actually block actions.
The policy was created and audited, but I could not demonstrate live blocking.
Even though I could not fully enforce the policy, I learned a lot about how KubeArmor works, how policies are written, and how Linux Security Modules integrate with Kubernetes.

That's what i have beem doing in these 4-5 days, great experience. Also, Hoping to hear from you soon!
