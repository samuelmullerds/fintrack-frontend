# FinTrack App

Aplicativo mobile de controle de gastos pessoais desenvolvido com Flutter, consumindo a [API FinTrack](https://github.com/seu-usuario/fintrack).

## Tecnologias

- Flutter
- Dart
- HTTP (consumo da API REST)
- JWT (autenticação)

## Funcionalidades

- Login e cadastro de usuários
- Registro de transações financeiras (receitas e despesas)
- Dashboard com saldo atual, total de receitas e despesas
- Resumo de gastos por categoria
- Listagem paginada de transações
- Redefinição de senha por e-mail

## Como executar

1. Clone o repositório
2. Instale as dependências com `flutter pub get`
3. Configure a URL da API no arquivo de configuração
4. Execute com `flutter run`

## Backend

O app consome a API REST do FinTrack. Certifique-se de que o backend está rodando antes de iniciar o app.
Repositório da API: [fintrack-backend](https://github.com/samuelmullerds/fintrack-backend)