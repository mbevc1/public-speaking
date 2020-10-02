#!/bin/bash

echo "Can fake-user use eks.limited PSP:"
AWS_PROFILE=test kubectl --as=system:serviceaccount:default:fake-user auth can-i use podsecuritypolicy/eks.limited

echo "Can fake-user use eks.privileged PSP:"
AWS_PROFILE=test kubectl --as=system:serviceaccount:default:fake-user auth can-i use podsecuritypolicy/eks.privileged
