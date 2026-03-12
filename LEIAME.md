# IRIS Gerenciação de Configurações

Implante uma API de gerenciamento de configurações em qualquer servidor InterSystems IRIS/Cache que exponha `/api/atelier`, capture o snapshot de configuração e compare com outro servidor em minutos. Esta extensão transforma um checklist manual e sujeito a erros em um relatório de diferenças repetível e confiável.

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/silver42labs/iris-configuration-manager-extension/blob/main/README.md)
[![pt-br](https://img.shields.io/badge/lang-pt--br-green.svg)](https://github.com/silver42labs/iris-configuration-manager-extension/blob/main/LEIAME.md)

## Navegadores Suportados

- Google Chrome (Manifest V3) [Chrome Web Store](https://chromewebstore.google.com/detail/iris-migration-checklist/anamganabilobholichagldbejkpclag)
- Mozilla Firefox (Manifest V3) [Firefox Add-ons (AMO)](https://addons.mozilla.org/en-US/firefox/addon/iris-migration-checklist/).

## Como executar esta extensão localmente

### Build

```bash
# Build para ambos os navegadores
./scripts/build.sh all

# Ou direcione um navegador específico
./scripts/build.sh chrome
./scripts/build.sh firefox
```

### Carregar no Chrome

1. Acesse `chrome://extensions`
2. Ative o "Modo de desenvolvedor"
3. Clique em "Carregar extensão não empacotada" → selecione `dist/chrome/`

### Carregar no Firefox

1. Acesse `about:debugging#/runtime/this-firefox`
2. Clique em "Carregar Add-on Temporário" → selecione `dist/firefox/manifest.json`

## Como usar

1. Navegue até o portal de gerenciamento IRIS do seu servidor de origem.
2. Clique no ícone da extensão e pressione **Salvar Dados do Servidor**.
3. Navegue até seu servidor de destino.
4. Clique no ícone da extensão e pressione **Comparar com Servidor Salvo**.
5. Uma nova aba se abrirá com o relatório de comparação.

## Arquitetura

Consulte [ARCHITECTURE.md](ARCHITECTURE.md) para detalhes sobre a estrutura do projeto, camada de compatibilidade do navegador e decisões de design.

## Privacidade

A extensão armazena todos os dados localmente e se comunica apenas com os servidores IRIS/Caché aos quais você se conecta. Consulte a [Política de Privacidade](src/docs/privacy.html) para obter detalhes completos.

## Licença

MIT — consulte [LICENSE](LICENSE).
