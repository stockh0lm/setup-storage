.PHONY: tidy move

FILES = shdd2 \
	shdd2-commands \
	shdd2-exec \
	shdd2-fstab \
	shdd2-init \
	shdd2-lib \
	shdd2-sizes

tidy:
	perltidy -bl -i=2 $(FILES)

move:
	for i in shdd2*.tdy ; do mv $$i `echo $$i | sed 's/.tdy//'` ; done

