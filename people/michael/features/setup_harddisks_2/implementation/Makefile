.PHONY: tidy move

tidy:
	perltidy -bl shdd2-*

move:
	for i in shdd2*.tdy ; do mv $$i `echo $$i | sed 's/.tdy//'` ; done

