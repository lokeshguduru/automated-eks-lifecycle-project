# Self-Validating EKS Cluster with an Automated Lifecycle

This project demonstrates a production-grade, highly available architecture on **Amazon EKS**, provisioned with **Terraform**. It showcases advanced DevOps and SRE principles by including an **integrated Chaos Engineering experiment** and a **CI/CD pipeline that fully automates the deployment, application setup, and teardown process**.

## Key Features & Best Practices Demonstrated

-   **Modular Terraform Design**: The infrastructure is broken down into logical, reusable modules, promoting clean code and scalability.
-   **High Availability & Self-Healing**: The EKS cluster runs on a multi-AZ VPC, with worker nodes managed by an Auto Scaling Group to automatically replace unhealthy instances.
-   **Infrastructure as Code (IaC)**: The entire cloud environment, including the chaos experiment and necessary IAM roles, is declaratively defined in Terraform.
-   **Automated End-to-End Deployment**: A GitHub Actions pipeline fully automates every step:
    * Provisions the EKS cluster.
    * Creates an IAM Role for the Load Balancer Controller (LBC) using IRSA.
    * Installs and configures the AWS LBC using Helm.
    * Deploys the 3-tier Kubernetes application.
    * Waits for verification and then automatically destroys all resources.
-   **Integrated Chaos Engineering**: The project codifies a chaos experiment using **AWS Fault Injection Service (FIS)** to prove the cluster's resilience against node failure.

## CI/CD Pipeline: Deploy, Apply, Verify, Destroy

The `.github/workflows/eks-infra-cicd.yml` pipeline is the core of this project's automation:

1.  **Trigger**: The pipeline runs automatically on any push to the `/terraform` or `/k8s-manifests` directories on the `main` branch.
2.  **Deploy Infrastructure**: The first job (`terraform-deploy`) runs `terraform apply` to build the entire EKS cluster and the IAM role for the LBC.
3.  **Deploy Application**: The second job (`deploy-application`) uses Helm to automatically install the AWS LBC and then uses `kubectl apply` to deploy the 3-tier application onto the cluster.
4.  **Wait & Verify**:
    * Once the application is deployed, the final job (`wait-and-destroy`) begins.
    * It waits for a **10-minute window**. During this time, the entire system is live.
5.  **Destroy**: After the 10-minute timer expires, the job continues and runs `terraform destroy`, automatically tearing down all AWS resources.

## Integrated Chaos Engineering Experiment

To validate the resilience of this EKS cluster, this project also includes a pre-defined Chaos Engineering experiment managed as code in `terraform/chaos.tf`.

### Hypothesis

The experiment is designed to test the following hypothesis: *"If a random EKS worker node is terminated, Kubernetes will automatically reschedule its pods onto the remaining healthy nodes, and the application will remain available with no user-facing errors."*

### How to Run the Experiment

During the 10-minute verification window provided by the CI/CD pipeline, you can perform this test:
1.  Navigate to the **AWS Fault Injection Service (FIS)** console.
2.  Find the experiment template named `eks-3tier-demo-EKS Node Termination Experiment`.
3.  Select it and click **"Start experiment"**.
4.  You can then monitor the automatic recovery in real-time via the EC2 and EKS consoles.

## Deployment and Verification Steps

### Step 1: Trigger the Pipeline

1.  **Configure Secrets**: Ensure your AWS credentials (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) are stored as secrets in your GitHub repository settings.
2.  **Push a Change**: Commit and push a change to any file inside the `/terraform` directory to trigger the pipeline.
3.  **Monitor the Pipeline**: Go to the "Actions" tab in your repository. Wait for the `terraform-deploy` and `deploy-application` jobs to complete successfully. The final `wait-and-destroy` job will then start, and your 10-minute verification window begins.

### Step 2: Verify the Deployment (During the 10-Minute Window)

You now have 10 minutes to connect to the cluster and verify that the application is running correctly.

1.  **Configure `kubectl` Locally**: On your own machine, run the following command to connect `kubectl` to your new EKS cluster.
    ```bash
    aws eks --region us-east-1 update-kubeconfig --name eks-3tier-demo
    ```

2.  **Check Pod Status**: Verify that the application pods are running:
    ```bash
    kubectl get pods -w
    ```

3.  **Get the Application URL**: The pipeline automatically installed the Load Balancer Controller and created the Ingress. Find the public URL by running:
    ```bash
    kubectl get ingress main-ingress -w
    ```
    *It may take 2-3 minutes for AWS to provision the load balancer and for an address to appear.*

4.  **Test the Endpoints**: Once you have the URL, test it in your browser:
    * **Frontend**: `http://<your-alb-url>/`
    * **Backend**: `http://<your-alb-url>/api`