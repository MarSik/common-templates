
# i.e. fedora28.yaml
ALL_TEMPLATES=$(wildcard templates/*.yaml)
# i.e. fedora28
ALL_GUESTS=$(ALL_TEMPLATES:templates/%.yaml=%)


TEST_UNIT=$(ALL_GUESTS)
ifeq ($(TEST_FUNCTIONAL),ALL)
TEST_FUNCTIONAL=fedora28 ubuntu1604 opensuse15 centos7
endif


unit-tests: is-deployed $(TEST_UNIT)
$(TEST_UNIT): %: %.syntax-check
$(TEST_UNIT): %: %.apply-and-remove
$(TEST_UNIT): %: %.generated-name-apply-and-remove


functional-tests: is-deployed $(TEST_FUNCTIONAL)
$(TEST_FUNCTIONAL): %: %.start-and-stop

test: unit-tests functional-tests


is-deployed:
	kubectl api-versions | grep kubevirt.io

%.syntax-check: templates/%.yaml
	oc process --local -f "templates/$*.yaml" NAME=$@ PVCNAME=$@-pvc

%.apply-and-remove: templates/%.yaml
	oc process --local -f "templates/$*.yaml" NAME=$@ PVCNAME=$@-pvc | \
	  kubectl apply -f -
	oc process --local -f "templates/$*.yaml" NAME=$@ PVCNAME=$@-pvc | \
	  kubectl delete -f -

%.start-and-stop: %.pvc
	oc process --local -f "templates/$*.yaml" NAME=$@ PVCNAME=$* | \
	  kubectl apply -f -
	virtctl start $@
	sleep 2
	# Wait for a pretty universal magic word
	virtctl console --timeout=5 $@ | egrep -m 1 "Welcome|systemd"
	oc process --local -f "templates/$*.yaml" NAME=$@ PVCNAME=$* | \
	  kubectl delete -f -

%.generated-name-apply-and-remove:
	oc process --local -f "templates/$*.yaml" PVCNAME=$@-pvc > $@.yaml
	kubectl apply -f $@.yaml
	kubectl delete -f $@.yaml
	rm -v $@.yaml

%.pvc: %.pv
	kubectl get pvc $*

pvs: $(TESTABLE_GUESTS:%=%.pv)
raws: $(TESTABLE_GUESTS:%=%.raw)

%.pv: %.raw
	SIZEMB=$$(( $$(qemu-img info $< --output json | jq '.["virtual-size"]') / 1024 / 1024 + 128 )) \
	set -x ; kubectl plugin pvc create "$*" "$${SIZEMB}M" "$$PWD/$<" "disk.img"

%.pv-minikube: %.raw
	SIZEMB=$$(( $$(qemu-img info $< --output json | jq '.["virtual-size"]') / 1024 / 1024 + 128 )) && \
	mkdir -p "pvs/$*" && \
	ln $< pvs/$*/disk.img && \
	bash create-minikube-pvc.sh "$*" "$${SIZEMB}M" "/minikube-host/pvs/$*/" | tee | kubectl apply -f -

fedora28.qcow2:
	curl -L -o $@ https://download.fedoraproject.org/pub/fedora/linux/releases/28/Cloud/x86_64/images/Fedora-Cloud-Base-28-1.1.x86_64.qcow2
fedora28.raw: fedora28.qcow2
	qemu-img convert -p -O raw $< $@

ubuntu1604.qcow2:
	curl -L -o $@ http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
ubuntu1604.raw: ubuntu1604.qcow2
	qemu-img convert -p -O raw $< $@

opensuse15.qcow2:
	curl -L -o $@ https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.0/images/openSUSE-Leap-15.0-OpenStack.x86_64-0.0.4-Buildlp150.12.12.qcow2
opensuse15.raw: opensuse15.qcow2
	qemu-img convert -p -O raw $< $@

centos7.qcow2:
	curl -L http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz | xz -d > $@
centos7.raw: centos7.qcow2
	qemu-img convert -p -O raw $< $@

# For now we test the RHEL75 template with the CentOS image
rhel75.raw: centos7.raw
	ln $< $@

clean:
	rm -v *.raw *.qcow2

.PHONY: all test
