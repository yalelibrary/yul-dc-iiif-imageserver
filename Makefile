NAME   := yalelibraryit/dc-iiif-cantaloupe
TAG    := $$(git log -1 --pretty=%h)
IMG    := ${NAME}:${TAG}
 
build:
	@cam build iiif_image
	@docker tag  ${NAME}:latest ${IMG}
 
push:
	@docker push ${IMG}
