


release: main
	@echo "Build release"
	@arm-none-eabi-gcc --version

main: main.c
	@gcc $^ -o $@

version:
