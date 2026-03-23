srpm:
	dnf install -y git rpm-build
	mkdir -p rpmbuild/{SOURCES,SPECS}
	git archive --format=tar.gz --prefix=dell-fanctl-1.0.0/ HEAD > rpmbuild/SOURCES/dell-fanctl-1.0.0.tar.gz
	cp dell-fanctl.spec rpmbuild/SPECS/
	rpmbuild -bs rpmbuild/SPECS/dell-fanctl.spec --define "_topdir $(shell pwd)/rpmbuild"
	cp rpmbuild/SRPMS/*.src.rpm $(outdir)
