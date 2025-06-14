# 🍈 Cantaloupe - Docker image build

Docker build for Cantaloupe IIIF image server.

Sample URL:

`http://127.0.0.1:8182/iiif/2/1014333/full/512,/0/default.jpg`

## Use for local development

1. Clone this repo: `git clone git@github.com:yalelibrary/yul-dc-iiif-imageserver.git`
2. Edit `.env` -- add your AWS credentials and uncomment the block for the Yale or DCE S3 bucket
3. Build the container: `cam build iiif_image`
4. Run the container: `cam up iiif_image`

You should now be able to go to `http://127.0.0.1:8182/iiif/2/1014333/full/512,/0/default.jpg` in your browser and see an image.

## Build an image

Build the container: `cam build iiif_image`

### Using the Makefile

You can also use the Makefile to build an image locally, and/or push it to dockerhub:

```
make build <- build the cantaloupe image

make push <-push an already build image

make build push <-build and then push the image up to dockerhub
```
When you use make build, a new cantaloupe image is built, and tagged as both :latest, and the current git sha.  When
pushing to dockerhub, only the git sha version is pushed.
```
yalelibraryit/dc-iiif-cantaloupe        d915b32 <-git sha   1c2d8977cf5b <- note same image id
yalelibraryit/dc-iiif-cantaloupe        latest              1c2d8977cf5b
```
In the case above, only  yalelibraryit/dc-iiif-cantaloupe:d915b32 will be available on dockerhub.


# Cutting Releases

Releases can be done through camerata or a combination of Docker Hub and GitHub UI.  For details on camerata please see that README.  To cut a release via Docker Hub and GitHub one needs to build the image locally, name and tag the image, push tagged image to Docker Hub, and then use releases workflow in GitHub.

```

docker push yalelibraryit/dc-iiif-cantaloupe:v1.0.2 <----- pushes up to docker hub

docker tag yalelibraryit/iiif_image:v1.0.5 yalelibraryit/iiif_image:latest  <----- tags to latest

docker tag yalelibraryit/dc-blacklight:DownloadOriginalFeature docker.io/yalelibraryit/dc-blacklight:DownloadOriginalFeature <----- tags a branch

```

# Environment variables

These are set the .env file and in AWS

## AWS key

Set both `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.

## Other variables

Set the source and cache AWS S3 bucket names:

```
S3CACHE_BUCKET_NAME=my-cache-bucket
S3_SOURCE_BUCKET_NAME=my-source-bucket
LOG_APPLICATION_LEVEL=warn
HTTP_HTTP2_ENABLED=true
```
## Set Honeybadger API key

If you are expanding or otherwise working with Honeybadger in development, set `HONEYBADGER_API_KEY_IMAGESERVER` (project reference in .env example)

# Image ID and lookup

## Key prefix

All image keys are prefixed with `ptiffs`

## Pairtree

Identifiers are assumed to be numeric OIDs. Last 2 digits are placed first for randomness. If the OID is made up of an odd number of digits, the final digit is ignored when constructing the pairtree path.

For example:

OID `12345` results in `/ptiffs/45/12/34/12345.tif`

OID `123456` results in `/ptiffs/56/12/34/56/123456.tif`

## Image type

Assumes images are TIFF and end with the `.tif` extension.

# License

Cantaloupe is open-source software distributed under the University of Illinois/NCSA Open Source License; see the file LICENSE.txt for terms.
