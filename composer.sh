#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.15.2
docker tag hyperledger/composer-playground:0.15.2 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� X�Z �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H��t�\z�{�PM����b�;��B���j����pb1�|F�����G|T�$I���#��E9�������� x�X��������B��,[3�M�&�1����� {�a �Ǆ����_�5Y��F��\���a�5�d�Hm +2�)��1-��Hk��I��1rz�բ�*�CWw<Dt� ˀ��ظ�}\�S��uX�4%��n�t>�{�At<���C���8�y��{�d
|��?��-��Y������/]��� ����$r����/��E��"5͈Ԡ�dlӵ�է@Q釪Yd���/�ry�}y�ZJe�p�.Y��?�:=���M�"��,�E��'�O������[,���)��X:� !KVۚ����|����_�.�r�_,���)�߁J���S�4��������O��1Q����` `������:�u��o.̅^��l��:������@����1iY�6��gR�.�@ݴ �t��F���N��"{:>ߎ�u�R��;��h��p��V�^�� ���͡�p�k�$��8{3�9M�V�vd��c��&�q�K��NӴh�H�%<�tMA�My�Xk�($�9/���=�Rm���)�x eM7��҄�1H�M�%jA�QJ^#ۣ��\MWC�R�Zٴ�����k:ao�FHV�Q�p{�Q*2hLB�O�p"��!��ƹ�e�aѯ� ��������%p��\.W��n���u=MO�ug�Ν���x|9�/���+�]C!�p��-M�4T`���E8�5�h�lfX�v���g���[�OU:�@�����k���[�e�������4M��b~�6�l��a�Qx	"x�FW��Q�ǁ�I)3u3ƙ� w�Z�%R��۰�ڀ�:�{IZ1;l@3�j����=�I[�C�mv0���i��fI`�H�#���1����s(�S�t�)V�i�:#����S�A�N� ����A��S��1�9D\�;رB��>�(&Wt5�"��&��w���<��btml�#����4�I-������zJ'���F�����6g	3���@3H������X�D��\�8�� ��Quz@;�/F����^Ӽ�Z����Й���Ȇ
��Z.�_+LY��@���_w���I��r�_,��n������'3���ؤ���r�g!��I��>�g�y�t�f��G�1��Y����y6�kY� �4��cZ}&�+m}�l�Tvr���T)wP��OM�/Ʊ���]�w�V/ȗkD$j+�α�����\��a�T����]��f��C �\�F�:��m�M4�z�g1�	\��X?�6��&�H<����,,,qT��[�ȥ��J.�ٯV��zm����w�j?�R���[��Ձ���Z��.�x�|u�$` oހթ���V-޽C��ږ׊�	
���p�5d����j���%m2���:��7+dx�]����"���(��(b��5���'w`�dOq��`��'Į���p���� ���z�T���&�:�����
����e�A��R����]�7�,|E
��0����s��,���ܤ��
K�_ܿ�3O>��{bt�@3p��:���P���`!Ǆ��K��������4?���ǹ����^�����5
f����'�,*���������<�f��p����Ɩ��B`��7C�p��N�e; Y�i����� �nCC��q�C�KV{䐳.�B��b�Rjg�W�.����7o�?z��-7]���Q�W�.�ɱ���ڀa�)#߈^d�B����Q��V$�'R��H��s+d""�7p���
�I����'V��:�s$<Jµ0=!Ʀ��|e��'�-��VՠnG~
0��E��"0v�����g�d6�Ν1�16�͇�6��;h����-�m��y.��Z���d�w4*q��0����+�58��~���\
i�蔳
r|��kafDJ�@��A�ڤ@�saq� �{���}�;Jd�JS�����o���\
���X�'�?Q����B`�����0'}�n�l� ���z�^�Y3�p��6� $�F~4:xI6�Er|��ҏ�/�Qo��av(4 �o �Z ���L���3/=�.׼'�ù��������!�Zٴ��:���SC�m��M�P��j�D���50"7<މb�M��"!����X}z�b�h����xrRɹYv�8!�gc�T.�נ��֘�l��`����.d9Z]#{��a���g��ς� �;�L4�U��Q�{�)��x4�X�?���1\xa���[e3�uӴ��8'q,����|
$��cw&ˈ��H*�M����lwtDlm�ҧE��1a�@�a���>�xE����k��mXu�N�P ���+�B�C���"R�W/v�������A�_���6� m��c��N.M��q#�������t��8����0�ܡ\ɼ��o]�����8&qh�Z#B�ӄ�viXdd��#�M"���r%�U�I}#</BX�P<V�sJ|#�m�7����%!
QD6�6T�)Q�S ����0EQ���[L*S�,Dj[kDW�C
��p�iP�hċ-��B.��P��i�-�";�SJuG�&0�L�\rG4@H!��4��C-�<$�
b[ �1�w�N��τ\a"˄dZ��/�*�' ߗ�>��$�.�d����jd����2W�������������$q"�K�� K�o���-f#�ږm��t�N����+&�'xuɘ��G�3�"���}\P���_�I������B`^���.�ᑟ��O�+f������?����eH�4�naq�tUF�L� fxm!"�ga���;��v�k�\�۵�5.٧���]��\1������2���n�r��02o���ʮ��Ow	��5��������`��w����>�Ǘ���;��h󦧰s6������I���?I�.���}˼g�}�������������X~�Ek�"�Bb���
/&`�V��D"V�%Q�C$�H���Z"**PLH�_�oHBmC�V��[�/�2��W�a�N�tt�s��f�;������U�I��mZ��W�����`��_߬��q"���wߌ�,�{��c�������f�����7��7Gv^-{�Vc��&qJ�D�p���O���d��=�����Z�w�q��?�-����G��p��6<f������xl9�/.|��(�N\M�iCO��L�<.��2�����z�bq.2p�Nn���d*�y����h����1ʼG7��6�v�!1��df;W �|"�ͥ�J���5�\j�4���TC��r#W��qXx�W#����:����^�ǹ]�$w~�e0nO9��a
rk[櫙d3�:<̟e��R�Q8Ĥ*�V�Y��۵�+eβ�r��S*�C��%��J;�����q�]�_{f%��蟜gܓ��f�u�>)K�5�;�I����W2B����kO���4�B���
�9!_�q���pD�Ni7H{k�&k���K�Ӈ��v���z���qÑڥ��ݢ����IWiK��J�(�,z5?��U!��2'��#��.���3�|��r�wT<*9�H�q[�������l��{�B�VI���L淓��弘���T������\NNn��g�"��:+W��^7^x���JN,���Ty��1�ZG�q�T��]y7ղ�I��I���Ko��WJ�1��n�vO+��^^q_`i�t/��􊤏wi9O�z��O����|*���Mj��z�V>�+�m���d.�xkX��Vo��������������J�������f�S2א�j*WL��n1��Hej�c$n��t��4����tNBe��;LtSj��k��ݘ�.��f��t`&��'�n����0�s 9���Z��䭷�Bz������H8�˞i4�4��@sL`��k��'^�1[��������g�e��Mx��P���޹;D���뾄���?:y���e��b `'��`7sLS3���^�����6׃Ć*����%wM-��Z��c�d_>���kT�>����M#弴[4��M��,��n�.V�N��:��T�����N���j<f��V�_,I})�#�z�#lk�T�Ȩ��[�� 9������N�Cm��7�|�13\��V�S�����abv��1C�yQ�|��DBB��� ��Ob�u��y�$f^'���Gb�u��y=$f^���?b�u��y�#f^爙�1׺F_xL�]����ī��������sk���Kx�y��4�o����@���&�r����m�2��߮K�š����J�ؐ30޳2�tV���gG7b��U���ǌ��=��[������a��h��lv��ݽֹc8mC>��{��;�;�Q������
:p��}�V���G��VL�o����z�[�.���xRf�oѸ�\2�Y�0�u�H�J��5�<!Q��ס=�7!�,��!k����0b�� Sc���}�a� Ҩ���5�$�wt-��䪤�
S���O��R�/qB�g� �C�@_�=� @�lC����Z�~߼	E��A
��2B��iEPC�٣!�d����/�z i�(����[�;�?����(&��2��<��m�:x��ȝ���`���dA�Q8M����d�k��� tF��4�Hp��tr��M���y�k�q �q ��
z�F=hЇ)���Vn>�uO=
>Zm�  h hY�O�D,�ci�ƴ3x��	o���ǨN�x��U_ߞLh OK胫a���4����Re�а����N�p���76���)�Ϩ,d��9~����a���4�^�R6U��K�I�CWwֽ���	o��؍�^\�����_�H��do$⿛�F��a��m�Pwq�#t�0��C��!)�P�*��\�;d�u��?��̶��_7M����N����)�����q�+�	��ƈ�ε��B�y0*����޳�8�d53;Mΰ;�w>4�bz�om�3�N�mi3�i;]N��9���t��N�3��-jiFZ��q��=p�� \V �\q��q���tMW�HS1��Ȉ�����U�qIevvI����n��xs��v������@H#��c%�Ѥ4��'"6|F�^��K B<)���g�Ĵ�!�i5�λ�C�Oޚ��GD�v]k��rM�����x�C$	��J~�s����WcU[�?h��?����If{�+ kr�3�s`�H�`�?|�A�UPv���!��A�F3g'0Ŝـ� �Ɓ&X�˖3���,݋d[�t}���7:ėem�]�� �(�9T`���C�W,�4�{��q��Že���� �Ӿ�5� �VG�|?����e��cP�G��#���b��|���5.)
�fǏ�4�TQ�1D<tkzC=B��Z�K6����kc ���(��m\��'RI|{��&����������g��y�~�_Z������'�_h���>���������_c?$�O���~�ދ�����{?AoE^�^א�IC��{�t2�T5	�RI5��hD
O�2��$rZ�J�2��Q)%GR�U	���R6G�I�Eʱ���������[�?���'���O�l��>�~��'��ñ����c��&������7c�s�������C��}���Ǿ&�����~��c?��7���DC\�7�5�6
��lY�����c�s%��O�.������'�z���'�
^c׽;�����qO`��@h�3������ vIn��.Hk_TW4)�t�I�Nz�[zy�0J�"�����zW��CQh
.����	��,&�Qn)�́��}+q.!�!���<�GՉBV�Bs�\T��[0`�ʢ2:Lu;�+۳.�s���uT�ŸE��ۢv��A56l�D�˰�����W�%3R+��D%as=�q����> VNu��ىi��Cj�F�Y���`U(T�-�ԝk�f;
R��
���n6�:�(%��^	t]����t��1���.*,z��.��W�ݩ7R�7��䘧��K���D�T:a�2��Tz����e�;���Զ�� �4��ӓ��>q���邃-rY�Z��vz��ORy[U���2��|��T�TZ�wZm�I�Yz>��bm���D9����v+q����?����J�J�zF%�ױ�[%���R��?^J(-���P�p�#�h易��V{��̏�g�����5.��Z\�0({>���`�P�^[�`P�\O�d�h ���[�p�t=���h�_�ӳ1�,fʳ�!+{=��t�L�#����9/�V�S"����6)�i�Í�N�R��tM5W?��5q-�O5җ�,�?�"~2=�����\
��\���WG5�6S��D��\Bɨ|�M���B��\��f\!�ֈQ��)�f3m�-��=g,��S��0��G�=g�jiHj\�vph�۽vm��1�R���G�lz�]@e��D�����/�{1�V�^���K�^x�*|��ka|����5�w�W������/7��S�e�2�~�{_����ୄ_.���$|H�}x���c�{�//�^��v�j�?|�e�~�V�߾�E.�b?��?���?���������̿���UV����Z��Nv^m��3�e��4��j_9#�%�y��K���'��^qca9��$�8v�Y �3�\�u��(��<��p9�g]��́��p�d�Q�*JG�EFW|a�3k�!0���I�i�̊(�2�t>]�c'u�p��r�z�3?Ps#�Z��-�#��3J�ΏdM�'E�Y�R���wVG�BY7�I��"�.v$�5��d��GbY����2z����,]���HCfZJy�*�7&�H2�����/���2G*Z��-�l�в��W��!(�j�f�6h�H[�GE�����E�(�Հ�㔜hأa�U0���\3'��`�Db���A���z�q�ß�S	��Vb��3��E���ߺ�h�PQ�CE��-'x�=j�J��Vj�>4Wg�����������l+ȅ}(��:�#R�:bE.)��e��[V��jZ ����0�=<�*�cץ���1���]�{@�+�9k�&±�rUN�NT�6:��3�%�^��ݢ-Ϊ�=�1��j%�7���D�
C6�1͊���樗#������q�ȟ�*�nuO�U��w�p�h�S�9OQ�4�x�r��.o�zg�(Ko�S�^(-�ٟ�e:����#��)��eጨn��?�iv�e�Z�w��K���V'\����1&��ݑt��Ң��謘�K��0_2x.C����u�Vn@�8��b�AY����t⿺�&�"$˵ ��Qc2>223��1u %�3Z�+��+H,�H��dQ�G���Pt�0��{l�_(L$��I��@��{��J�<N6ڇ�A~�g��V���ԁ�q�)Wć.o�����-^'�՞8!$�ε���8��6�m�pPL���ln`��`
%�u
H�%Ӯt����8�\I#���m��y�Ԡ�N4r��Sl(�����yC�����2��*Sy1#(��C�D��(�����2IJ#���a2F;!1nk��g�Hv&�p+��%ؔ�{=��k�X��]DL�^�\�ľt����ע�[X��ƫ�I�U�+W
u�_����hS����݊���*���4W�3[\N���W��m˴�"��c$G���{#��=���O�o?}�|{�=Gy���^�^"מ}>¾��;�C�4Tχ���tEoB�z%
��=���d��N�� FP��|�����h��H~���M����?�����šUu�ٶfǨ��m��)z��<:���Bf�����]�<��О�Y\���K���t���������t3��P��j?�]O�=��F��!���n��Sa�Z\CQ��� ��� ����TJ��i*�4���@4��4��L����?"{�|�&Di>�-z����~<��]g������?򿰞U��Q`#t�f�8�Ǐ֧=���5�f����gA^�bتo���D���N��h7,q�cj"_�==��7��-�$h�!��QKPϠ�7��?j=,�q�1�|�,�M��~��J
�h�3��kdLEoշ�9�Dz��Mǁ����G���������T�c�,8(h���3��3o��� d��|m��l�,��4b	�ƣ�{;H❸�?���F��s�h�Ez�c������'u�Ȩw���k�1�����Ά�>�\�B�#5"�p#&~��y6
EA�?Ycض"��E��H���X�����j?�J�
{���+'�!��B��>$�P�����It��nX�cŘH�~�i�'0\[/�N|)��k/$�f�.��+�0���CXW�wTh��)|v��a߉~�X�o=�ME.��"J�kH��Բm��_��`6��?`ТӷME��pi��oѺ�����oqd�dFKȡ!qhg�gA��F��1l�8uZRB��7'q���ת�g@����=D@�Q�ɧ�8ЏǶ�U����!N�?ɚj&�l]+\7#m<M)d��������g�Ah��A*�����8���K��=� 5=C���\�!��}8��C�3;���Z�E���-�����x�E�q���4�V���l�OW2� � 2 �"T�˰.�=ُ��&tx����3�L{��z��D#h�2
�^G06$���^ݨ��HZ��hW �D���P��l����IZ`��G[�e0�3 �a������U��]��N,׳���@�뵩!�`X꺋�=^�8�	в�p.�h��H��[��7	?<���� (|S����c�A���}�Ed�M���n{���v=!A��9�t�i��ZC(@�Q�;0tT&.{�#	�D��ebG Uk"��"r��}7nl9��I���&��c�G�������y�jtт��nAN�1M��P:���<|����8�:�Xs\k:��Ʀ��ܙ��ȱ�RDpގ8��������bG�z����g>�;���6.y�Oe����T2��;����ޏ�O��a��Jv�\�x%
�����pdó~g]��&�?���02ғ��(���|��Q��5�&��J;:��sQ-xyV�+Wh|�k=/X�p�gkG"IU�'��LJ�Ler�&QI-I��龢h}B��	I"�$�?G�r_���R*��$2-���h ؋<n#lya�P��h������xo��AN���WŎ	'̃9Ԗ���Ir��dY�SY<�J*Aj)�r�$�ө����鬖�d���`&�9-��)-i`b�d/��>�9q�T/���m#-2]��=��"%��:	����;�]X
��쬿��%�׸�֚,�X]�\��Wj�
w�U���<��/ƷD�J�l�k���H���-�m�-�K5�	:꿤�n�
N��y�v���tEh�y�I�x��0��.�����s�{�#;V��L8	݂�j	{�$t��d�Kg�j�h;n�}���P�,�ӵQ���0��x'�l��3Z�}@��/8L9�a���{��� ��j��q�-DG��%���k캤G,Ǵ��E�c���k|U|2��D"�Y'��41��}���OT6~0��ӣhـ�ΙMt���7��? UK����U|�ʉ�Z�@ �{��q���f���H�-r=�uZ,����X֋��EP�%����'K�4C��'yk�X���Z;_bL�_�)��*�S�l�h�%��0�?{��䓾d��9$Ll.�7��N�G�!�o����+H>t6�؍l�)k���.�c����O��M��j�/w���|���(�����/w1�	@ls�����F��e���
hb;p*��i����ٶ��������M޳��JQ8y��6��\��4���g^�$NB��w��鹯�}��O������F�R��������;�߷�n���V�넍�K��nc����������e��$�o�*������n�����_	|���M���/��Em��B����Vҝ�;4wh���/���)})�?jG��;��V�m�����.���Y��ɪ�)W�~�R4URr�,�h�,��'�$�IʙTV�qU#R���7��_��e��'���/y��VRD��������g�ښE��=�⻷j8�.ު�����n�DDQTP�_�jҙ�i�I:����U*�I�bֳ��{�gњ��<ަ���{�5�{���9�F�q@gY8<�O��r�s�Fut�,F��m؅ҝ��C�D?O\�]�ڄs�>[x#<'�rv֒v�z��!�ˤ+�I�OS/�J����|��u:<�p���_>���gC�~��Ǩ������q���@�����$�����a6������_?������_���G���Ԯ�-�� �����q����_	��O���A p���?���O3��� �W�f��S��aJ�:T���6�I�=�3���pU'\�	Wu��#�?�F�?���'�T�����6@����_#����� �����M��i�~����J�Z�o���p������K�sZy��!���B���,k��t1}���o��ȏ�~޾��]�ݻ���O�}��E�y��UF����>_�>��I��L���:k��ֻ��y�D�h��t^���.��27��#�,	s�=虓Q����e�n'���3r���K���ϗ�O�{�>;^���L��D�ma��7�ۣ�eJ1'S����l�^,w{��>��a�&�*g��9r湄.[q�a�hGI�<�g��?F�ڙ&�C3�ib9�H�l9��{p��M݅����g���������O�`���?��k�C��64��!%�j4�������ߕ � �	� �������#@�U��,�`��.@����_#�����w�����@����A���hB��������Z��_��Lاb���43����ڿq�������s]���/����K�\�#����î�c[��'Ϊ����HJ�h���~�Q-���6gc}�Ǩ�/6��*��*�Q�K%/s�}w�,��L<�;,�:�c��=������PЅ⩮W�w$]
���_��Y���6>���kߺ��.���nI �s�i�[3�6��p;[��{R4Ў�u0K���}&��x�QJ����I.?n����*/]\�O��xc�������������������!��@����_��������J�$��/|�4>0���S��<�XH���$Cz�`d�4ɓ>bpG���	��(���j�3�����j�s,�C����w:��y��y*���>�G~G���or��ڞ����+��vyEs.��K�2[���zz��`�.7[R�+GY�Ĳ�����s�Ft�ɏ��Y��]��+�p�C�g}������֊&��P�ՇF�?��Ԇ����ǵ�����h�C�W~f�w4L�>jJ봝Dld!Gw�`��8��A	�+�]�f���S�$3P�R4Dc�3.��wF��%�D��tv)la�(#�S*;c�uI
��8�lk�)�"�S0�Bmߥ��{+�q���ք����Gp���_M������ �_���_����z�Ѐu���e��A�����?��꿈���?���#	^x�L��YƕX9�����Z��Ka����ގ2䪶�?r ���� ���}x�U��q���J�]�� �yZ�������SR+�-����a�[mT�z��ooW�%�:R�����6�y�������\��U���o���*r��\󁾛D_^�-����J�; L�-�x�b��ū�D��.��E�h��X�}/�C/��gL�5���2]��7Ls��-��w��5!!����o]1%Uk�v8��(7?��@l�fZW���BV�[$e����e�A_��Uȣ���D2B�oR�KM�>��,8:��ힶ_�^4h��é���W>��<��h.�x���������`��
4���O���������L�Ƣ*�����%�������������?��_*�8������Q�ν9N�T�y��yC�!�q��?���1���bC�c�;?M����>���>?s����u��z�Y�6�бO�ǂt���Z�1U2�N�&~���F�?�E��bY%��ӭ�q��˝Z��nHq��7�a:�ei6�˘��JDWY0�cWw��OO�m�0��M�ߊ&��8����*����-��W	�'T�����3�h�3w�?��U�j�ߛob�xo"����������`��"T������B;�!����7�������������u��8�c�u��b�N�8U։y7����˂�2������������������.��9�ބw�Eyu��s䴳h��ٲ�q�?��4�i��3�������ד1��������ͭ8�u�e�]!s�Ū�>��R.���V�-�u�� �^����~{��H~�8��9�ޑU�G����6���
���f����]���Sّ�+����i&�HJ���YHq^��]n�+�thm'N1�O���Ȣ5&���<m���S�B�٣�L�zw�a�E�x�47��������wU{p�oM�F����M���[�5��	���ךP-�� x�Є����7C@�_%��o����o����?迏�y���H@����_�����r��\�������_����
@�/��B�/��������������/��u����������4��	���I��*P�?��c�n �����p�w]���!�f ��������������5���v�������Y��U�*����
�*�?@��?��#?�F�?�������� ��!5��ϭ�������Eh��ZHhB��(�����J ��� ��� ��5�?��P�n�����mh�C8D�hD�� �����J ��� ���Po��@�A�c%h����������[�5���?����4��a��r4������ ��0����t	�Ch����?�_h��[��,O!��5 ��ϭ�����7����:4��q�*},d�,Gb܂��E@�\�S^	����x8�z�����{E���}�'��E��dp��k�_���H_+��Ӕ�K���^+N��*P����0��Ԣ��4F�x�3�;Ƙ�OC�3I�SҖài�8.G�!	��p�2�1F;�Y�mOb[��HI�����k�b���NB�w�NI���Iӣ= B�Tv���ܵ�p��2ե���݋��o�p�C�g}������֊&��P�ՇF�?��Ԇ����ǵ�����h�C�W~f�7H�>��]�[[m���"����u��e��S�ޗ��׹u��D�A�&��:���l.�K1�;O��3~n�{ԙE�0������ý.$�C�#5�(﷫�R���ފf��w����[p����w|o4a�����������?����@ցF���#�����5�7x�������^:&��t`����V'N���7���g�gmw�v��n����:yK���;���Ж|Z�{�����a]�B沿��j7�#K;�~4a�QFM�`i+f%�e��df��1;��F�32��Ƚ��D_��[��ӣ�n����]�~b�������t��e��	]4����9�E���2?�B��D*�!�t@Z�̠-�_]1%�˞}g����B��t�17Ws=��͹v��ȷ:���	����s��}/U�y�N�֜�4�u�t+<��5���hvo�����A�O����������_�š�[	>��{���?'��W�&�8� ���+�G��?%���WcQ���~��0� ��M����������s=!ӣy����5�������� �_x��3lI旯��qژ��4f�:΋���#��\��?;��-�K��D|�,M�γ�&_�K�4A�{��)�,?��~�X~�W��,��KϷȿ�.=]�^���ͺ�9���䯱%[��(�⴪�W�U��6Pg����Mڵ2&��
2��d�Q�����;Eʄń�N�i���-{�{��[3�ż�L�8�x�!��;�b�+��犩-�[�ܓ���y��vnr}��͔�ׂ,_l?�����.�KO�����(��ӟ�{�%��mYx!>ʶ��Nhפ[��8�Y{�޵�q�#�+Ȣ"�"���'�գM�|���x"��0���p� TB�!�Z�H���A=���3��m�B�sn����2�\l�&�5������~/h��������[���Oc>����.8�"<~A�w�6�����?�X,E��d}&�,�y�� ��f�G�	����������J�3��e&Z]7?���O|Q��a6��{ou{g���bN,]1�2�/W��V��ȕ�Z�������o��;�?4Ƃ�W���p�����U�
����k0�x������������˛��}��Ԝ;�,���b(�h���������A��2P����w3ؐ�y�?�����n���o��΋�7x��^l?�m��Iƹ�5�ow�##1����핉�̐���9����S�Y�o��kˀ��ٮS�g�2n1)��v/��]o|�����~/�����|��Ģ�F��,:-i�b���{A��yֶ��DPg�RАǾ�O��z8����t6�1��ᔥ����D�0�G�l�v� Ѯ�U���Ly��Kq.�$l��m��z�zb����.׿����&�?�����V�
��c*��1r�ĭ�0ׯh6�O{��y�k�ܛ���4�?���I�:S���\tj�T���ej*/������}�mӝhv:�i;���$F�Yϻ�z�U��-F�f%�&5���g�R��oH��������{{~f��Te֞L��֪�v;�ŉ���T7��J�2D�s`��<��}ݶ$��Q������������d��� �/v{����i��Z��+<f������Б����@�pPfHK��p����Y��T�������?��ؙ�E�;�]�.����ͻ����^�a���K�����>J'nxY���n�/E�OD<5���b�296�YY��M��r~���h�뗑+�G��.#W��ҕn�txq -��jב_W�{Y��O�Y8#��mmծ�ɉ�w���qݞ٬�ˑ�x��$-+�w�f8���i��m�Qڜ[r�Ų0mrLo�m6bp����5����x^�Qhp\T;��,x�)��zcwڔbK���^Y�<;�ok��4#��Vڂ�6�Ju��v;ʜkh��1.�My:4��h��<Q��{㋖����!V�n�s8�ҧJrU��B�QD����b�<'�*N�d_�Л�z���7�i����[����TH��74��
����������:����=2�_��d����
0����O��	����ު���.�L��}��,�?���#e��Bp#��U��8����T��oP��A�7����-����_���i|���S8���	�g��C�ϔHG����C��@�A����������
��?�D}� �?�?z�'�����SJ��������O�X�� �O���?ԅ@DZ��}�b���� �����_2��������
(�$����������U����Y��AG&�������?@��� �`��_���B��������GFF��B "��U��8����T��P��?@����7�?��O*���c���@���/�Oݨ� �R!���Q�����#�������d����� ��[�� ��&�������_��H\����CJdB��$�K�֌2E��L�ʤI�6��%�4ْIcX�^��-4e�e�-28C���˓�/2��?��O�����(W'��_�r��5����r�A���˂��8���GZ�7���sZ�̩S�+��/L0_j2��j$[�*��׼���VC�w�d���p�V�$��d�'��vP

S[;�(b�Ě�9S)|_`����V��uڶ$�����-�]o�qvI��J��//�:����I���#�?��D��?\��o�B��:���0�(����q��*�/Y�����3�?^�����mrT�8��|T6L5m{5i	�.�;{һ�5q�l͚��r����o�����4Q�a�p���X���۬�¶ff��K�����v��\mF.e�.ԅ@;���%�����7���/�_�L����/d@��A��A��?D�?��	�G3����/�Y�������_�i����F�Z��#�|��9�'M~��{>�
/�S���%���_v�a/{�8\��Ʀ;��8N�z��W{���g-���OF����[6��v�o�rl�6�xݮ�Z��6V��+jmW)��ߦ��B���G���y��UJئ���\o ��&��mQ�;F�1M!��|gPM��
����$%�M������
�د�|/-���)��8G��tj:[�%��lH��U&5�U���a��L��~�g�I)L�J�|D>��qz�Ҁ*���.���ZՃ�u����{I�AC�'T�u�����Q����5��_��(�I�?��x{2����/�?R���/k�A����������4� ��$	��s@�A���?q#��R���X���G@�A���?uc���M�,�?T�L������?��O���4���P��?�/��č�_������
�H�����_&��@Ff��DB&��:����T�f��)��О�?���o��o�cSd�cffW�Z?��#�:O�����$V`?���|��H>�3�I�����q�\r[���K�����N�	{�"�*�cF�W��)-:X�iS�}mV^��W�I5���ԩ��ֺi���)�%kt�%�vO&i�؏��^�~�y��.���l�Xr^�Y6��͖S�ñ2�z���S&�W�n��r��<.�cY'���z=$�9f��%[��B'X/����6���ÃN�"
s�5����O�n}�,T�`(�U��v����L�?�Gr��bp��������_&�����%�|� �����F�/��S�A�/��������� ��{^���K ��o��	��q�DdH�o�: ޚL��0�ߊ�+�d������v��U�!�w\�4T�v�1�R��������H�/�ͽ���xIS�� ��?�r J�`+��G�j�5���JJE3
�Q�i�k��6i���{fP��p�)��>	��Fq8/��t����zƢ���!�� ,I�39 X��G9 ݈���b�j���,z\�P�}%\��̸*6۲À�ϥ��w�{��w����)�j54	�����^�y���0y��f���_>��a2����@��T@��>-��J�'�߷�˂������i����khEֲ���%͜q��h\g(��I�$�R٤	��5�,�0u�1�%��1���~��2Y��[����t�����)�s(���'S�=aC?���F,��^0�v[����IX�_��<換1Y��������Gv�;���\�0yI+�ܳ�����g*s*9d~q���9��i6���X�,�c� ����p���,��P�H��d(����B��:2��0����i�8D})�,�?�����7ڭF󅤷e�/�p�RXR�h�7�^�JM�3)x|䄝�%�cz��[��
U��\jU"�^ј{���!�W�~avl��]��{��dݠ\��ګM���*���"!�{-�h������h�����������/��B�A��A�����C��Y�4]���o��Q��l�����ǌ�}�*�y|1
[ܽ�����O9 ?���X vY�e@~i;m%2�V�:y�a��jEA�w\�4�X�%sXn�}*c�B�XLKlxd������Ŗ�/���k��z�(M��m�_-~y���a���5.�v�|�x�J-��|gP墤O0���@⣆�e� v+a�$2>��=�y���]-���x���`�1����x���7wy!>��ҏ4��X]����(�O��~��p O!��Km�U�fӓ��'w�.�pǕ==6��������1J���20�a}���^�Iu�תS�3L�.Q���a�n��o�p����!<�������T��>��b�,���s�ts���B3��q������ᨭcE=x?�I�U���$ls��o�ۣ
v~]xHv���7��2s��/�u�
r�1��>lv�����X�>��>���z���(�5�5W�]	��ӓ��˝�'�_l��X��.������Ƽ��O�Pz��̿�3�1�G0������$�&���o�����;nAׂ9��-'�0�qs��a�����Ϝ�;n��V��Yk�,x�3�}0��{*fh���6r�G;�ĸ�P��_;W[�r��W�g���\87s����x3Ǐ_��XE�����?r�,��ox|����^�c�5�
�������������9/�ŏ�b�Oz����ł����:��J����wϭ��y8�W��"�'�f��>̒���Z?W=z��2g����wN.��o��e�kh��7��*�hk��s]ǵs�X��O���9'vf�s����n�c_i��A���^i~�I�n����`�1������kǂ�iz_��YK��ד:��9>��y����&^��O_^�3λ��������i<��/58��34
��W�4��<9Xu�_;����8�����C�Z]�c[����jJ��؞]D���}</S��'%/x���H����?�x�                ��<����w � 