SELECT
	rs.Netbios_name0 AS 'Device Name',
	CASE
		WHEN os.CSDVersion0 IS NULL THEN os.caption0
		WHEN os.caption0 IS NULL THEN 'N/A'
		ELSE os.caption0 + ' ' + os.CSDVersion0
	END AS 'Operating System',
	MSSQL.InstanceName0 AS 'SQL Server Instance Name',
	MSSQL.ProductName0 AS 'SQL Server Product Name',
	MSSQL.Version0 AS 'SQL Server Version',
	MSSQL.PatchLevel0 AS 'SQL Server Service Pack',
	MSSQL.Edition0 AS 'SQL Server Edition'

FROM
	v_ClientCollectionMembers ccm
	LEFT JOIN v_R_System rs on rs.ResourceID = ccm.ResourceID
  JOIN v_Gs_Operating_System OS on ws.resourceid = OS.ResourceID
	INNER JOIN v_GS_DEMO_SQLSERVERINVENTORY MSSQL on MSSQL.ResourceID = rs.ResourceID

WHERE
	ccm.CollectionID = @collectionName

GROUP BY
	rs.Netbios_name0,
	os.caption0,
	os.CSDVersion0,
	MSSQL.InstanceName0,
	MSSQL.ProductName0,
	MSSQL.Version0,
	MSSQL.PatchLevel0,
	MSSQL.Edition0
