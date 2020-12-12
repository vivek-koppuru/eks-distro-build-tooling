# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -o pipefail
set -x

echo "Running job.sh in $(pwd)"

yum install -y jq

KUBECTL_VERSION=v1.18.9
curl -sSL "https://distro.eks.amazonaws.com/kubernetes-1-18/releases/1/artifacts/kubernetes/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /bin/kubectl
chmod +x /bin/kubectl

secret_name=$(kubectl get sa default -o jsonpath='{.secrets[0].name}')
CA_BUNDLE=$(kubectl get secret/$secret_name -o jsonpath='{.data.ca\.crt}' | tr -d '\n')
cat /config/mutatingwebhook.yaml | sed -e "s|\${CA_BUNDLE}|${CA_BUNDLE}|g" > mutatingwebhook.yaml
kubectl apply -f mutatingwebhook.yaml

for c in $(kubectl get csr -o json | jq -r '.items[] | select(.spec.username=="system:serviceaccount:default:pod-identity-webhook" and .status=={}).metadata.name'); do
    kubectl certificate approve $c;
done

