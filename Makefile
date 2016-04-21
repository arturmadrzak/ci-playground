


release: main
	@echo "Build release"
	@mv main ex_main

main: main.c
	@gcc $^ -o $@

version:
