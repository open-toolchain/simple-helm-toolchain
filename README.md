# ![Icon](./.bluemix/secure-lock-kubernetes.png) Secure Kubernetes with Helm toolchain


### Continuously deliver a secure Docker app to a Kubernetes Cluster with Helm Charts
This Hello World application uses Docker with Node.js and includes a DevOps toolchain that is preconfigured for continuous delivery with Vulnerability Advisor, source control, issue tracking, and online editing, and deployment to the IBM Bluemix Containers service using Helm Charts.

![Icon](./.bluemix/toolchain.png)

### To get started, click this button:
[![Deploy To Bluemix](https://console.bluemix.net/devops/graphics/create_toolchain_button.png)](https://console.bluemix.net/devops/setup/deploy/?repository=https%3A//github.com/open-toolchain/secure-helm-toolchain)

---
### Learn more 

* TBD Blog [Continuously deliver your app to Kubernetes with Bluemix](https://www.ibm.com/blogs/bluemix/2017/07/continuously-deliver-your-app-to-kubernetes-with-bluemix/)
* TBD Step by step [tutorial](https://www.ibm.com/devops/method/tutorials/tc_secure_kube)
* **First-time IBM Container Service users**: Make sure that your container image registry is correctly set up with a [namespace](https://console.bluemix.net/docs/services/Registry/index.html)
    * IMPORTANT NOTE: For the pipeline to build containers successfully, please use these steps to define your namespace:
        * bx login
        * bx target --cf
        * bx cr namespace-add <my_namespace>
* [Getting started with Bluemix clusters](https://console.bluemix.net/docs/containers/container_index.html?pos=2)
* [Getting started with toolchains](https://bluemix.net/devops/getting-started)
* [Documentation](https://console.ng.bluemix.net/docs/services/ContinuousDelivery/index.html?pos=2)

More linkks

https://github.com/kubernetes/helm/blob/master/docs/charts_tips_and_tricks.md
https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
http://helm.readthedocs.io/en/latest/awesome/
https://kubernetes.io/docs/concepts/containers/images/#using-a-private-registry
https://www.ibm.com/blogs/bluemix/2017/03/whats-secret-pull-image-non-default-kubernetes-namespace-ibm-bluemix-container-service/
https://console.bluemix.net/docs/containers/cs_tutorials.html#cs_tutorials
https://console.bluemix.net/docs/containers/cs_cluster.html#cs_apps_images

Demonstrating use of private image registry with a Kubernetes cluster.
It will automatically create a namespace in cluster, matching the promotion stage name (staging/prod).
It enables access by 
Only downside is if you decide to move your deployments to a different (non default) serviceaccount. You’d then need to patch that serviceaccount too.
Or if you start passing in other imagePullSecrets for other images in the same deployment… if `imagePullSecrets` is set on the Deployment, it does NOT get merged with the list in the serviceaccount - Kube will just use the list in the deployment.

  # grant access to private image registry from namespace $cluster_namespace
  # copy the existing default secret into the new namespace
  kubectl get secret bluemix-default-secret -o yaml |  sed "s~^\([[:blank:]]*\)namespace:.*$~\1namespace: ${cluster_namespace}~" | kubectl -n $cluster_namespace create -f -
  # enable default serviceaccount to use the pull secret
  kubectl patch -n staging serviceaccount/default -p '{"imagePullSecrets":[{"name":"bluemix-default-secret"}]}'
  https://console.bluemix.net/docs/containers/cs_cluster.html#bx_registry_other

