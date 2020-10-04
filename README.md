# makeluks

Script que ajuda a criar criptografia LUKS

Execute sem argumentos e selecione se quer criptografar um dispositivo (preferencialmente pendrive) ou um arquivo, ou com o nome do arquivo de imagem para monta-lo:
./mk-luks.sh teste.luks

Associe este script para abrir arquivos com a extensão "luks" (abrir em terminal), assim toda vez que você clicar nesses arquivos, o script irá abri-lo, e se ele já estiver aberto, ele irá fecha-lo.

Como a maioria dos desktops linux já estão prontos para montar pendrives com criptografia, eu não me preocupei em implementar isso.

Edite o arquivo para alterar mais oções como cifra de critptografia e sistema de arquivos a ser usado.

Este script é apenas um "FrontEnd" do "cryptsetup", ele não é responsável pela criptografia, apenas facilita o seu uso.
