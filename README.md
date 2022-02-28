# SQLServerInventorySCCM

Script PowerShell permettant d'automatiser l'inventaire des instances Microsoft SQL Server à l'aide de SCCM. 
Le script parcours la base de registre pour récupérer les infos sur les instances. Les infos sont enregistrées dans une classe WMI personnalisée. 
Cette classe WMI personnalisée peut être ensuite collectée par SCCM / MEMCM via l'Hardware Inventory.

Ce scripts est à déployer sur les clients Windows à l'aide d'une baseline ou package. 

Plusieurs fichiers sont mis à disposition : 
- CCM_SQLServerInventory.ps1 -> Le script pour effectuer l'inventaire des instances MS SQL 
- QRY_SQLServerInventoryReport.sql -> Query SQL pour créer un rapport personnalisé via la base SCCM / MEMCM

Configuration à adapter : 
- Modifiez la variable <b>$InventoryWMIClass</b> pour définir le nom de la classe WMI personnalisée à créer dans votre environnement. 
- Modifiez la QUERY SQL pour le rapport en spécifiant le nom de la classe WMI personnalisée.

Un article détaillant l'implémentation est disponible sur le blog : 
https://tobeadmin.com/sccm-inventorier-instances-sql-server
