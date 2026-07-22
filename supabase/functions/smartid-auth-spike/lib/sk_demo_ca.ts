// Pinned SK DEMO trust anchor for the spike.
// "TEST of SK ID Solutions EID-Q 2024E" — the issuing CA for current demo
// QUALIFIED test accounts (both the notification DEM2-Q and device-link MOCK-Q
// accounts observed live 2026-07-17).
// Source: AIA caIssuers of a live demo auth certificate ->
//   http://c.sk.ee/TEST_EID-Q_2024E.der.crt  (DER sha256:
//   063a4e908785a2b45fba27a22d45d9f2bbaa9a382e5b103e1d1036832cee6ac2 — re-check
//   with `curl -s http://c.sk.ee/TEST_EID-Q_2024E.der.crt | shasum -a 256`).
// This CA is itself signed by "TEST of SK ID Solutions ROOT G1E" (not pinned in
// the spike — the issuing CA IS the trust anchor here; production path B should
// pin the full chain to the root and check revocation/OCSP).
export const SK_DEMO_CA_PEMS: string[] = [
  `-----BEGIN CERTIFICATE-----
MIIDxzCCAymgAwIBAgIUIJ92Wg42THMIC1QSOpWpxv3+22AwCgYIKoZIzj0EAwMw
bjELMAkGA1UEBhMCRUUxGzAZBgNVBAoMElNLIElEIFNvbHV0aW9ucyBBUzEXMBUG
A1UEYQwOTlRSRUUtMTA3NDcwMTMxKTAnBgNVBAMMIFRFU1Qgb2YgU0sgSUQgU29s
dXRpb25zIFJPT1QgRzFFMB4XDTI0MDYwMzEzMDEyMloXDTM5MDUzMTEzMDEyMVow
cTEsMCoGA1UEAwwjVEVTVCBvZiBTSyBJRCBTb2x1dGlvbnMgRUlELVEgMjAyNEUx
FzAVBgNVBGEMDk5UUkVFLTEwNzQ3MDEzMRswGQYDVQQKDBJTSyBJRCBTb2x1dGlv
bnMgQVMxCzAJBgNVBAYTAkVFMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE9tnu4Hr6
oZ3virQ52FkQ8zgSnRLjSpbr7y6hjaI5ZtvFTssL3aOgvULxOvV5x+HtOmcGVfmh
vy9YtoJENq/E3pFFOkofrkX3O/RVLdtPpiVahYa89HCgqoEVDln5ILMWo4IBgzCC
AX8wEgYDVR0TAQH/BAgwBgEB/wIBADAfBgNVHSMEGDAWgBTiHN5j3L74hH4BOy5L
gLHhf9Xx5jBsBggrBgEFBQcBAQRgMF4wOAYIKwYBBQUHMAKGLGh0dHA6Ly9jLnNr
LmVlL1RFU1RfU0tfUk9PVF9HMV8yMDIxRS5kZXIuY3J0MCIGCCsGAQUFBzABhhZo
dHRwOi8vZGVtby5zay5lZS9vY3NwMHAGA1UdIARpMGcwBgYEVR0gADBdBgNVHSAw
VjBUBggrBgEFBQcCARZIaHR0cHM6Ly93d3cuc2tpZHNvbHV0aW9ucy5ldS9yZXNv
dXJjZXMvY2VydGlmaWNhdGlvbi1wcmFjdGljZS1zdGF0ZW1lbnQvMDkGA1UdHwQy
MDAwLqAsoCqGKGh0dHA6Ly9jLnNrLmVlL1RFU1RfU0tfUk9PVF9HMV8yMDIxRS5j
cmwwHQYDVR0OBBYEFLAkFxmI42b4zShYZXtNFNiSZk9rMA4GA1UdDwEB/wQEAwIB
BjAKBggqhkjOPQQDAwOBiwAwgYcCQXIdNKdyvEhtB+48QZEXi2dgXiAjYD7O0D4f
4Y2KPajqrRcwd9KEYr/yFjK0JWYHqRFN47tMdYhisy7aFySEWmKcAkIBUbTJeSbo
XAKBT9+j2zQduKv8Eqb/AIQybcVXyP23w+1ujNkcQZMkok41nGOH2YNRP7aGsCZa
7Wy8pf2lw6EcfyU=
-----END CERTIFICATE-----`,
];
