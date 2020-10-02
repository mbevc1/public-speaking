AWS_PROFILE=test kubectl create serviceaccount fake-user
AWS_PROFILE=test kubectl create rolebinding fake-editor --clusterrole=edit --serviceaccount=default:fake-user
