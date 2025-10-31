#Build the large image
$sourceImage = "run48-winiso-ltsc2019:latest"
docker build -f dockerfile-10G-random-win2019 -t $sourceImage .
docker images $sourceImage

docker image inspect $sourceImage --format='{{.Size}}'

#Tag the image for ACR
$acrName = "acrusw3391575s4halwincont"
$targetImage = "hal-dwp/run48-winiso-ltsc2019:latest"

docker tag $sourceImage "$acrName.azurecr.io/$targetImage"
#Push the image to ACR
docker push "$acrName.azurecr.io/$targetImage"
