(FR, see EN below at line 100) 

1. Téléchargez les dossiers Infra, Backend, Frontend et créez des repos gitlab (ou autre gestionnaire de version git) 

2. Installez les prérequis, notamment Ansible, Terraform, Python3, Pip, AWS CLI.

3. Installez les pre requis Ansible (ansible-galaxy collection install cloud.terraform)

4. Installez Kubectl sur votre machine localhost.

5. Faites en sorte que vos registry d'images soient disponibles au grand public pour que le process puisse push et pull les images sur vos futures instances EC2.

6. Login a votre compte AWS avec aws configure puis creez un profil groupe IAM avec les permissions nécessaires puis attachez un utilisateur IAM a ce groupe. 

6. a. Exemple de configuration pour l'utilisateur IAM : 
```bash
aws iam create-policy --policy-name PolicyIAC --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "elasticloadbalancing:*",
        "iam:PassRole",
        "iam:GetRole",
        "iam:ListRoles"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AllocateAddress", 
        "vpc:*",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackResources",
        "cloudformation:DescribeStackEvents",
        "cloudformation:GetTemplate",
        "cloudformation:List*",
        "cloudformation:Get*"
      ],
      "Resource": "*"
    }
  ]
}
```
```bash
aws iam create-group --group-name GroupeIAC
aws iam attach-group-policy --group-name GroupeIAC --policy-arn arn:aws:iam::VOTRE_ID_DE_COMPTE:policy/PolicyIAC
aws iam create-user --user-name UtilisateurIAC
aws iam add-user-to-group --user-name UtilisateurIAC --group-name GroupeIAC
```

7. Gardez la secret key et l'ID du profil IAM que vous avez créé proche de vous

8. Via la CLI AWS, créez un bucket S3 et gardez son nom, puis via la CLI ajoutez les permissions nécessaires afin de pouvoir faire des  requêtes GET/POST sur votre backend pour pouvoir aménager votre galerie d'image. 

```bash 
aws s3api create-bucket --bucket votreNomDeBucket --region votreRegion
aws s3api put-bucket-policy --bucket votreNomDeBucket --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":["s3:PutObject","s3:GetObject","s3:ListBucket","s3:DeleteObject","s3:PutObjectAcl"],"Resource":["arn:aws:s3:::votreNomDeBucket","arn:aws:s3:::votreNomDeBucket/*"]}]}'
```

8. a. Maintenant votre bucket sur la toile vous pouvez builder une première fois votre backend en pluggant le nom de votre bucket en build arg ainsi que votre ID AWS, votre clé secrète et votre région.

```bash
cd /iac/backend
docker build -t registry.gitlab.com/votreNomDeGroupe/votreNomdeRepo  --build-arg AWS_ACCESS_KEY_ID=votreAccessKeyID --build-arg AWS_SECRET_ACCESS_KEY=votreSecretAccessKey --build-arg S3_REGION=votreRegion --build-arg S3_BUCKET=votreNomDeBucket
docker run -d -p 3001:3001 registry.gitlab.com/votreNomDeGroupe/votreNomdeRepo
```
Normalement l'image tourne, et vous pouvez la tester avec curl et ensuite thunderclient (ou curl si vous préférez): 
```bash
curl http://localhost:3001 
Résultat >>> Hello world! 
```
Pour voir si l'image communique bien avec le bucket vous pouvez utiliser les forms de thunderclient pour faire une post requête avec une image attachée, faites le post sur http://localhost:3001/upload, n'oubliez pas de labelliser votre image dans le form 

Puis, effectuez une get request sur http://localhost:3001/gallery et vous trouverez bien votre image. 

Pour aller plus loin vous pouvez aussi builder votre frontend de la même manière et utiliser le http://localhost:3001 en build arg, attention, il ne faut pas push cette image sur votre registry. Normalement si tout marche vous verrez l'image que vous avez posté via Thunderclient. 

9. Les tests effectués, vous pouvez commencer à insérer vos valeurs dans les variables.tf 

9. a. Vu que je m'appelle raphael et c'est de l'iac j'ai mis raphaeliac partout dans le document, vous pouvez faire ctrl+f et remplacer "raphaeliac" par ce que vous voulez :)  

9. b. Vous verrez qu'il y a une adresse IP dans les variables labellisées EIP, ceci est une elastic IP qui nous sera utile pour le DNS plus tard. Veuillez créer une EIP via la commande ```aws ec2 allocate-address```, prenez uniquement les chiffres après PublicIP. De plus, j'utilise un VPC spécifique à moi-même, veuillez changer le VPC dans le main.tf . 

10. Les valeurs inserées, vous pouvez maintenant faire ``terraform init``

11. Pour bien vérifier si votre terraform est fonctionnel veuillez faire terraform validate, terraform fmt et finallement terraform plan. 

12. Si aucunes erreurs surviennent: ``terraform apply --auto-approve`` (auto approve pour les impatients comme moi ^^)

13. Le terraform applied, vous pouvez a present faire un `chmod +x autoscriptkube.sh` ansi que `./autoscriptkube.sh`. Le script devrait executer les deux playbooks ainsi que l'application du manifest (deploy et svc) de kubernetes. 

24. Voili voilou vous avez un frontend docker compose qui tourne en se connectant au load balancer aws de votre cluster kubernetes!  ٩(＾◡＾)۶ 


(EN) 

1. Download the Infra, Backend, and Frontend folders and create GitLab repositories (or other Git version control repositories).

2. Install the prerequisites, including Ansible, Terraform, Python3, Pip, AWS CLI.

3. Install the Ansible prerequisites (ansible-galaxy collection install cloud.terraform).

4. Install Kubectl on your localhost machine.

5. Make sure your image registry is publicly accessible so the process can push and pull images to your future EC2 instances.

6. Log in to your AWS account with `aws configure`, then create an IAM group profile with the necessary permissions and attach an IAM user to this group.

6.a. Example configuration for the IAM user:
```bash
aws iam create-policy --policy-name PolicyIAC --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "elasticloadbalancing:*",
        "iam:PassRole",
        "iam:GetRole",
        "iam:ListRoles"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AllocateAddress",
        "vpc:*",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackResources",
        "cloudformation:DescribeStackEvents",
        "cloudformation:GetTemplate",
        "cloudformation:List*",
        "cloudformation:Get*"
      ],
      "Resource": "*"
    }
  ]
}'
```
```bash
aws iam create-group --group-name GroupeIAC
aws iam attach-group-policy --group-name GroupeIAC --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/PolicyIAC
aws iam create-user --user-name UtilisateurIAC
aws iam add-user-to-group --user-name UtilisateurIAC --group-name GroupeIAC
```

7. Keep the secret key and the ID of the IAM profile you created close to you.

8. Via the AWS CLI, create an S3 bucket and keep its name, then use the CLI to add the necessary permissions to make GET/POST requests on your backend to manage your image gallery.

```bash
aws s3api create-bucket --bucket yourBucketName --region yourRegion
aws s3api put-bucket-policy --bucket yourBucketName --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":["s3:PutObject","s3:GetObject","s3:ListBucket","s3:DeleteObject","s3:PutObjectAcl"],"Resource":["arn:aws:s3:::yourBucketName","arn:aws:s3:::yourBucketName/*"]}]}'
```

8.a. Now that your bucket is online, you can build your backend for the first time by plugging in your bucket name as a build argument along with your AWS ID, your secret key, and your region.

```bash
cd /iac/backend
docker build -t registry.gitlab.com/yourGroupName/yourRepoName --build-arg AWS_ACCESS_KEY_ID=yourAccessKeyID --build-arg AWS_SECRET_ACCESS_KEY=yourSecretAccessKey --build-arg S3_REGION=yourRegion --build-arg S3_BUCKET=yourBucketName
docker run -d -p 3001:3001 registry.gitlab.com/yourGroupName/yourRepoName
```
Your image should now be running, and you can test it with curl and then Thunderclient (or curl if you prefer):
```bash
curl http://localhost:3001 
Result >>> Hello world! 
```
To check if the image is communicating correctly with the bucket, you can use Thunderclient forms to make a POST request with an attached image, post it to http://localhost:3001/upload, and don't forget to label your image in the form.

Then, perform a GET request on http://localhost:3001/gallery, and you should find your image.

To go further, you can also build your frontend in the same way and use http://localhost:3001 as a build argument. Be careful not to push this image to your registry. If everything works, you will see the image you posted via Thunderclient.

9. Once the tests are completed, you can start entering your values into variables.tf.

9.a. Since my name is Raphael and this is IaC, I've used "raphaeliac" throughout the document. You can use Ctrl+F to replace "raphaeliac" with whatever you like :)

9.b. You'll notice an IP address in the variables labeled EIP. This is an Elastic IP that will be useful for the DNS later. Please create an EIP with the command `aws ec2 allocate-address` and take only the numbers after PublicIP. Also, I use a VPC specific to myself, please change the VPC in main.tf.

10. Once the values are entered, you can now run `terraform init`.

11. To ensure your Terraform configuration is functional, run `terraform validate`, `terraform fmt`, and finally `terraform plan`.

12. If no errors occur, run `terraform apply --auto-approve` (auto-approve for the impatient ones like me ^^).

13. With Terraform applied, you can now run `chmod +x autoscriptkube.sh` and then `./autoscriptkube.sh`. The script should execute both playbooks and apply the Kubernetes manifest (deploy and svc).

14. There you go, you have a Docker Compose frontend running, connecting to the AWS load balancer of your Kubernetes cluster! ٩(＾◡＾)۶
