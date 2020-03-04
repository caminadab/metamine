# Assembly
.intel_syntax noprefix
.text
.global _start

.section .text

_start:
  jmp fn1_eind
fn1:    # (fn)(1)
  sub rsp, 8    # (arg)(1)
  mov [rsp], rdi
  sub rsp, 8    # 1
  mov rax, 1
  mov [rsp], rax
  mov rax, 8[rsp]       # (+)
  mov rbx, [rsp]
  add rax, rbx
  mov 8[rsp], rax
  add rsp, 8
  mov rax, [rsp]
  ret
fn1_eind:
  sub rsp, 8
  mov rax, fn1
  mov [rsp], rax
  sub rsp, 8    # 1
  mov rax, 1
  mov [rsp], rax
  mov rax, 8[rsp]       # (_f)
  mov rbx, [rsp]
  mov rdi, rbx
  mov 8[rsp], rbx
  add rsp, 8
  call rax

  # Exit
  mov rax, 60
  mov rdi, [rsp]
  syscall
  ret
