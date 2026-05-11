---
paths:
  - "**/*_test.go"
---
# Go Testing

## Framework
- Testing: `testify` (`require.*` only — fail-fast; `assert.*` allows tests to continue with broken state)
- Mocking: GoMock (`mockgen`) or hand-rolled — preferred for narrow interfaces
- Style: table-driven tests

## Naming
- File: `<source>_test.go` in same package
- Function: `Test<Function>_<Scenario>` or `Test<Function>`

## Table-driven Template
```go
func TestCreateAccount_Scenarios(t *testing.T) {
    tests := []struct {
        name    string
        input   CreateAccountRequest
        setup   func(*mocks.MockAccountRepo)
        wantErr bool
        errCode string
    }{
        {
            name:  "success",
            input: CreateAccountRequest{Name: "Test"},
            setup: func(m *mocks.MockAccountRepo) {
                m.EXPECT().Create(gomock.Any()).Return(nil)
            },
            wantErr: false,
        },
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            ctrl := gomock.NewController(t)
            defer ctrl.Finish()
            mockRepo := mocks.NewMockAccountRepo(ctrl)
            tt.setup(mockRepo)
            uc := usecase.NewAccountUsecase(mockRepo)
            _, err := uc.CreateAccount(tt.input)
            if tt.wantErr {
                require.Error(t, err)
            } else {
                require.NoError(t, err)
            }
        })
    }
}
```

## Running
- Single package: `go test ./internal/features/admin/... -v`
- Single test: `go test -run TestX -v`
- Coverage: `go test -cover ./...`
- Race detector: `go test -race ./...` (always in CI)

## Mock Generation
```bash
mockgen -source=internal/domain/repository/account.go -destination=internal/tests/mocks/mock_account.go
```

## Integration Tests
- Use `testcontainers-go` for real Postgres in tests
- Mark with build tag if slow: `//go:build integration`
- Run separately in CI: `go test -tags=integration ./...`

## Anti-patterns
- `assert.*` in tests (use `require.*`)
- `time.Sleep()` in tests (use `eventually` or mocked clock)
- Testing private functions directly (test through public API)
- Shared state across tests (each `t.Run` owns its data)
