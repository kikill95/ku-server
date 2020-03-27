kuserver
----

This is the backend project for kuserver app

Install dependencies 

    docker-compose run web npm i

To start server local you will have to run

    docker-compose up
  
or to easy debug the server you can run two commands in different tabs

    docker-compose up mongo worker redis
    npm run start-local
    
you will have to save all variables for server development.env file it you start with *start-local* command.
    
### Add a user

You need to add first user via cli, easy to do

    docker-compose run web ./app/bin/add-user

Or just in bash

    ./app/bin/add-user
    
## Development

While on admin development process, you will have to add your IP to config.admin.host to be able to login as admin.

### Run migrations

To run a migration you will need to get a shell to a running web container. Firs to get a list of containers run

    kubectl get pods
    
Select any web pod from the list. To get a shell run 

    kubectl exec -it <name-of-web-pod> -- /bin/bash
    
And after entering the shell, run the migration script

    node app/bin/migrations/<migration-version>.js
    
or for local environment

    docker-compose run web node app/bin/migrations/<migration-version>.js

or with this command if you need environment file

    node -r dotenv/config ./app/bin/migrations/<migration-version>.js dotenv_config_path=development.env
    
Migration version should consist the package.json version
    
## Deploy to production on GCP

Download *values.yaml* from secret place

Attention: version in *values.yaml* (in root) should match with version in *TAG=<yyyy-mm-dd>* command

Setup:

    * install [docker](https://docs.docker.com/install/)
    * install [gcloud](https://cloud.google.com/sdk/docs/quickstarts)
    * install Python@2.7
    * on windows install [chocolatey](https://chocolatey.org/) as package manager for next steps
    * install [kubernetes](https://kubernetes.io/docs/tasks/tools/install-kubectl/) - manage everything
    * install [helm](https://docs.helm.sh/using_helm/#installing-helm) - DRY, pass variables to *yaml* configs
    * `kubectl apply -f ./charts/kube-setup/tiller-sa.yaml`
    * `helm init --upgrade --service-account tiller`
    * `helm install --name cert-manager --namespace cert-manager stable/cert-manager`
    * if this is your first time of working on GCP with combination of docker, run this command: `gcloud auth configure-docker`
    * `gcloud auth login`
    * `gcloud config set project PROJECT_ID`
    * [create](https://cloud.google.com/kubernetes-engine/docs/quickstart) cluster in GCP or connect to the existed one with: `gcloud container clusters get-credentials <cluster> --zone <zone> --project <project>` - this can be found in GCP in `kubernetes clusters`, tab after pressing `Connect` button
    * You need to be `owner` on gcloud to run next commands
    * Wait few seconds
    * For the first time proceed `cert-manager` step
    
If changes in code (TAG here should match with tag in `values.yaml`)

```bash
export TAG=<environment>-<yyyy-mm-dd>f<version during the current day>
./docker/build-prod && ./docker/push-prod
```

For example, TAG can be "test-2019-09-05.f.1"

If changes in configurations of **Test server**:

    helm upgrade -i kuserver-test ./charts/kuserver-server/ -f values-test.yaml
    
To ease the work with git add tag after each exported tag

     git tag -a <yyyy-mm-dd>f<version during the current day> -m "<yyyy-mm-dd>f<version during the current day>"
     git push --tags

If this is the first time you create the app you will need to install certificates

Documentation about cert-manager:
### [cert-manager](https://github.com/kubernetes/charts/blob/master/stable/cert-manager/README.md)

To get a service-account.json file follow this steps
  
### [Managing service account keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#iam-service-account-keys-create-gcloud)

Then add the service-account key to GCloud secrets with 

OR from a terminal


```bash
ROBOT=clouddns
DNS=[[YOUR-CLOUD-DNS-PROJECT]]
gcloud iam service-accounts create ${ROBOT} \
--display-name=${ROBOT} \
--project=${DNS}
gcloud iam service-accounts keys create ./${ROBOT}.key.json \
--iam-account=clouddns@${DNS}.iam.gserviceaccount.com \
--project=${DNS}
gcloud projects add-iam-policy-binding ${DNS} \
--member=serviceAccount:${ROBOT}@${DNS}.iam.gserviceaccount.com \
--role=roles/dns.admin
```

Download you service-account key to the computer and add it to GCloud secrets. You will user it in certificates manifest

```
kubectl create secret generic clouddns \
--from-file=./clouddns.key.json \
--namespace=cert-manager
```

If you setup mailer for the first time

```
echo "export SENDGRID_API_KEY=<SENDGRID_API_KEY>" > sendgrid.env
echo "sendgrid.env" >> .gitignore
source ./sendgrid.env
```

Firebase cloud Functions
---
All firebase cloud functions and setup are located in /app/bin/firebase directory. To update the cloud functions of firebase you will have to install `firebase-tools` util global

    npm install -g firebase-tools
  
`cd` to firebase directory and run next command

    firebase deploy --only functions

Troubleshooting
----
If you are experiencing problems with GCloud access, like *could not find default credentials*, try to set local environment variable with 

    export GOOGLE_APPLICATION_CREDENTIALS="./clouddns.key.json"

This variable only applies to your current shell session, so if you open a new session, set the variable again.

To remove all previously built images from your system, you can run next command

    docker images -a | grep "kuserver" | awk '{print $3}' | xargs docker rmi
