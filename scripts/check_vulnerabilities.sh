#!/bin/bash
echo -e "Checking vulnerabilities in image: ${PIPELINE_IMAGE_URL}"
for iteration in {1..30}
do
  [[ $(bx cr va ${PIPELINE_IMAGE_URL}) == *No\ vulnerability\ scan* ]] || break
  echo -e "${iteration} : A vulnerability report was not found for the specified image."
  echo "Either the image doesn't exist or the scan hasn't completed yet. "
  echo "Waiting for scan to complete.."
  sleep 10
done
set +e
bx cr va ${PIPELINE_IMAGE_URL}
set -e
[[ $(bx cr va ${PIPELINE_IMAGE_URL}) == *SAFE\ to\ deploy* ]] || { echo "ERROR: The vulnerability scan was not successful, check the output of the command and try again."; exit 1; }