# 🍈 Cantaloupe - Docker image build

Docker build for Cantaloupe IIIF image server.

Sample URL:

`http://127.0.0.1:8182/iiif/2/1014333/full/512,/0/default.jpg`

## Use for local development

1. Clone this repo: `git clone git@github.com:yalelibrary/yul-dc-iiif-imageserver.git`
2. Edit `.env` -- add your AWS credentials and uncomment the block for the Yale or DCE S3 bucket
3. Build the container: `docker-compose build web`
4. Run the container: `docker-compose up web`

You should now be able to go to `http://127.0.0.1:8182/iiif/2/1014333/full/512,/0/default.jpg` in your browser and see an image.

## Build an image

```
docker image build -t registryaccount/name:tag .
```
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


# Environment variables

## AWS key

Set both `AWS_ACCESS_KEY_ID` and `AWS_SECRET_KEY` environment variables.

## Other variables

Set the source and cache AWS S3 bucket names:

```
S3CACHE_BUCKET_NAME=my-cache-bucket
S3_SOURCE_BUCKET_NAME=my-source-bucket
LOG_APPLICATION_LEVEL=warn
HTTP_HTTP2_ENABLED=true
```

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
