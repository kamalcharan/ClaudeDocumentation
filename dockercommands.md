cd "D:\projects\core projects\ContractNest\contractnest-combined\contractnest-ui"
docker build -t vikuna/contractnest-ui:v2.30 .
docker push vikuna/contractnest-ui:v2.39


cd "D:\projects\core projects\ContractNest\contractnest-combined\contractnest-api"
docker build -t vikuna/contractnest-api:v2.95 .
docker push vikuna/contractnest-api:v2.95