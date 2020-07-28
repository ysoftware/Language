	.section	__TEXT,__text,regular,pure_instructions
	.macosx_version_min 10, 15
	.globl	_testStaticallySizedArray ## -- Begin function testStaticallySizedArray
	.p2align	4, 0x90
_testStaticallySizedArray:              ## @testStaticallySizedArray
	.cfi_startproc
## %bb.0:
	movabsq	$12884901888, %rax      ## imm = 0x300000000
	movq	%rax, -8(%rsp)
	movabsq	$8589934592, %rax       ## imm = 0x200000000
	movq	%rax, -16(%rsp)
	movq	$1, -24(%rsp)
	movb	$1, %al
	testb	%al, %al
	jne	LBB0_1
## %bb.4:
	movl	$1, %eax
	retq
LBB0_1:                                 ## %if.7.continue
	cmpl	$2, -12(%rsp)
	je	LBB0_2
## %bb.5:
	movl	$2, %eax
	retq
LBB0_2:                                 ## %if.12.continue
	cmpl	$3, -4(%rsp)
	je	LBB0_3
## %bb.6:
	movl	$3, %eax
	retq
LBB0_3:                                 ## %if.17.continue
	xorl	%eax, %eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	_testDynamicallySizedArray ## -- Begin function testDynamicallySizedArray
	.p2align	4, 0x90
_testDynamicallySizedArray:             ## @testDynamicallySizedArray
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	subq	$16, %rsp
	movl	$6, -4(%rbp)
	movq	%rsp, %rax
	leaq	-48(%rax), %rsp
	movq	-48(%rax), %rax
	cmpl	$1, (%rax)
	je	LBB1_3
## %bb.1:
	movl	$4, %eax
	jmp	LBB1_2
LBB1_3:                                 ## %if.6.continue
	xorl	%eax, %eax
LBB1_2:
	movq	%rbp, %rsp
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	_main                   ## -- Begin function main
	.p2align	4, 0x90
_main:                                  ## @main
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r14
	pushq	%rbx
	subq	$16, %rsp
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	movl	%edi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	leaq	L_l1_StringLiteral0(%rip), %rdi
	xorl	%esi, %esi
	xorl	%eax, %eax
	callq	_printf
	callq	_testStaticallySizedArray
	movl	%eax, -20(%rbp)
	testl	%eax, %eax
	je	LBB2_3
## %bb.1:
	movl	-20(%rbp), %eax
	jmp	LBB2_2
LBB2_3:                                 ## %if.7.continue
	movq	%rsp, %rbx
	leaq	-16(%rbx), %r14
	movq	%r14, %rsp
	callq	_testDynamicallySizedArray
	movl	%eax, -16(%rbx)
	testl	%eax, %eax
	je	LBB2_5
## %bb.4:
	movl	(%r14), %eax
	jmp	LBB2_2
LBB2_5:                                 ## %if.13.continue
	leaq	L_l1_StringLiteral1(%rip), %rdi
	xorl	%esi, %esi
	xorl	%eax, %eax
	callq	_printf
	xorl	%eax, %eax
LBB2_2:
	leaq	-16(%rbp), %rsp
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
	.section	__TEXT,__cstring,cstring_literals
L_l1_StringLiteral0:                    ## @l1_StringLiteral0
	.asciz	"Array: "

L_l1_StringLiteral1:                    ## @l1_StringLiteral1
	.asciz	"OK\n"

.subsections_via_symbols
