	.section	__TEXT,__text,regular,pure_instructions
	.macosx_version_min 10, 15
	.globl	_main                   ## -- Begin function main
	.p2align	4, 0x90
_main:                                  ## @main
	.cfi_startproc
## %bb.0:
	pushq	%rax
	.cfi_def_cfa_offset 16
	movq	$1, (%rsp)
	movq	l_a(%rip), %rsi
	incq	%rsi
	leaq	l_format_d(%rip), %rdi
	xorl	%eax, %eax
	callq	_printf
	xorl	%eax, %eax
	popq	%rcx
	retq
	.cfi_endproc
                                        ## -- End function
	.section	__TEXT,__const
l_format_d:                             ## @format_d
	.asciz	"%d\n"

	.p2align	3               ## @a
l_a:
	.quad	3                       ## 0x3

.subsections_via_symbols
