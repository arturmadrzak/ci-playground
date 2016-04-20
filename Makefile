


release: main
	@echo "Build release"

main: main.c
	@gcc $^ -o $@

version:
