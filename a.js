
D = [108, 111, 111, 112, 116, 105, 106, 100, 58, 32];
H = _argA;
G = H < 0;
if (G) {
  I = [45];
} else {
  I = [];
}
F = I;
P = Math.abs(~V);
O = Math.max(P,1);
N = Math.log(O, 10);
M = Math.floor(N);
L = 1 + M;
K = [...Array(Math.abs(0-L)).keys()].map(a => L > 0? a + L : L + 0 - 1 - a);
W = _argA;
V = Math.pow(10, W);
U = ~V / V;
T = Math.floor(U);
S = T % 10;
R = 48 + S;
Q = ~V[R,~CG];
J = K.map(Q);
E = F.concat(J);
C = D.concat(E);
B = tekst(C);
A = print(B);