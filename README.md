# 🦈 SharksPeak v2 — FLL Visual Programmer

> Plataforma completa da equipe Sharks para programação visual de trajetórias FLL.

---

## Arquivos do projeto

```
sharkspeak_v2/
├── index.html           ← site completo (HTML + CSS + JS em um arquivo)
├── supabase_setup.sql   ← SQL para rodar no Supabase
├── sharks.png           ← logo da equipe (coloque aqui)
├── equipe.png           ← foto da equipe (coloque aqui)
└── README.md
```

> **Importante:** `sharks.png` é usada tanto como logo quanto como imagem do tapete FLL no canvas. `equipe.png` aparece na seção "Nossa equipe" da landing page.

---

## Setup Supabase (5 minutos)

### 1. Criar projeto
1. Acesse https://supabase.com → **New Project**
2. Escolha nome, senha forte, região mais próxima (ex: South America)
3. Aguarde inicializar (~1 min)

### 2. Rodar o SQL
1. Vá em **SQL Editor → New Query**
2. Cole todo o conteúdo de `supabase_setup.sql`
3. Clique **Run**

### 3. Pegar as credenciais
1. Vá em **Project Settings → API**
2. Copie:
   - **Project URL** → `https://xxx.supabase.co`
   - **anon public key** → chave longa começando com `eyJ...`

### 4. Configurar o index.html
Abra `index.html` e substitua as duas linhas no topo do `<script>`:

```js
const SUPABASE_URL = 'https://SEU-PROJETO.supabase.co';
const SUPABASE_KEY = 'sua-anon-key-aqui';
```

---

## Criar e gerenciar usuários

### Fluxo de cadastro
Os usuários se cadastram pela própria plataforma (botão "Criar conta").
- Por padrão entram como **Montador**
- Admin promove via painel ou SQL

### Promover para Admin / Programador
No Supabase **SQL Editor**:
```sql
-- Promover para admin:
select public.set_user_role('email@exemplo.com', 'admin');

-- Promover para programador:
select public.set_user_role('email@exemplo.com', 'programmer');

-- Ver todos os usuários:
select id, email, name, role, created_at from public.profiles order by created_at;
```

Ou use o **Painel Admin** dentro do site (disponível para usuários com role = admin).

---

## Permissões por função

| Recurso                     | Admin | Programador | Montador |
|-----------------------------|:-----:|:-----------:|:--------:|
| Landing page                | ✅    | ✅          | ✅       |
| Cadastro                    | ✅    | ✅          | ✅       |
| Ver tapete e trajetórias    | ✅    | ✅          | ✅       |
| Desenhar trajetória         | ✅    | ✅          | ❌       |
| Salvar / editar missão      | ✅    | ✅          | ❌       |
| Deletar missão              | ✅    | ✅          | ❌       |
| Carregar missão             | ✅    | ✅          | ✅       |
| Gerar e copiar código       | ✅    | ✅          | ✅       |
| Painel Admin                | ✅    | ❌          | ❌       |
| Alterar role de usuários    | ✅    | ❌          | ❌       |
| Ver logs de atividade       | ✅    | ❌          | ❌       |

---

## Publicar o site

### Netlify (recomendado — grátis)
1. Acesse https://netlify.com
2. Arraste a pasta `sharkspeak_v2/` inteira para a área de deploy
3. Pronto — URL pública instantânea

### GitHub Pages
1. Crie repositório público no GitHub
2. Suba os arquivos (incluindo `sharks.png` e `equipe.png`)
3. Settings → Pages → branch main → Save
4. URL: `https://usuario.github.io/sharkspeak`

### Vercel
```bash
npm i -g vercel
cd sharkspeak_v2
vercel
```

---

## Configuração do Supabase — confirmação de email

Para que o cadastro funcione sem precisar confirmar email (útil durante testes):
1. Supabase → **Authentication → Settings**
2. Desative **"Enable email confirmations"**

Para produção, deixe ativado e configure um domínio de email personalizado.

---

## Como usar o app

1. **Acesse a landing page** → clique em "Entrar na plataforma"
2. **Faça login** ou crie uma conta
3. **Desenhe a trajetória** no tapete FLL:
   - Modo **Clicar**: cada clique adiciona um ponto
   - Modo **Desenhar**: segure o mouse e arraste
4. **Salve a missão** com um nome (ex: "Missão 3 — Energia")
5. Clique em **"{ } Gerar código Python"** → copie e cole no Pybricks

---

## 🦈 Equipe Sharks — FLL
SharksPeak v2.0 — o pico da programação da equipe.
