# SharksPeak v3 — FLL Visual Programmer

## Arquivos obrigatórios na raiz

```txt
projeto/
├── index.html
├── tapete.png
├── sharks.png
├── equipe.png
└── supabase_setup.sql
```

## Como instalar

1. No Supabase, rode `supabase_setup.sql` no SQL Editor.
2. Coloque `index.html`, `tapete.png`, `sharks.png` e `equipe.png` na raiz do projeto.
3. Publique no Vercel/Render/GitHub Pages.
4. Teste a URL `/tapete.png`. Se der 404, o tapete não foi enviado para a raiz.
5. Crie a conta pelo site.
6. Rode no Supabase, se quiser admin:

```sql
select public.set_user_role('tomboly.academico@gmail.com', 'admin');
```

## Funções incluídas

- Login/cadastro com Supabase.
- Perfil: montador, programador e admin.
- Tapete FLL real via `tapete.png`.
- Clique para adicionar pontos.
- Desenho contínuo.
- Ponto zero livre.
- Missões com cor por saída.
- Salvamento/carregamento/deleção de missões.
- Simulação com timer, barra de progresso e timer FLL 2:30.
- Ações: IR_PARA, T, A, GMU, GMD, V e W.
- Edição de etapa clicando na lista.
- Geração de código Pybricks.
