Class Migration.Framework Extends %CSP.REST
{

XData UrlMap
{
<Routes>
    <Route Url="/export" Method="GET" Call="GetSnapshot"/>
</Routes>
}

/// Aux method to map out all available versions
ClassMethod GetMethodName(pBaseName As %Library.String) As %Library.String
{
    // Commented the method separation because for now
    // there is no need to reimplement specific methods for specific versions
    #; Set currentVersion = $ZVERSION
    
    #; If (currentVersion [ "2025.1")
    #; {
    #;     Return pBaseName _ "202501"
    #; }
    #; ElseIf (currentVersion [ "2017.2.2")
    #; {
    #;     Return pBaseName _ "202702"
    #; }
    #; Else
    #; {
        // If there's no specific method for the version, use the generic which may work.
        Return pBaseName _ "Generic"
    #; }
}

/// Initial method. Meant to be called by the extension using the /api/atelier/query option as a stored procedure
/// call Migration_Framework.Setup()
ClassMethod Setup() As %Library.Status [ SqlProc ]
{
    ZNspace "%SYS"
    Set name = "/api/v1/configuration-manager"
    Set currentVersion = $ZVERSION

    If (##class(Security.Applications).Exists(name))
    {
        $$$ThrowOnError(##class(Security.Applications).Delete(name))
    }

    Set props("NameSpace") = "%SYS"
    Set props("DispatchClass") = $CLASSNAME()
    Set props("Description") = "Part of the IRIS Configuration Manager Extension. Uploaded at " _ ##Class(%Library.UTC).NowLocal()
    Set props("AutheEnabled") = 32

    If (currentVersion [ "2017")
    {
        Set props("CSPZENEnabled") = 1
    }

    $$$ThrowOnError(##class(Security.Applications).Create(name, .props))

    Return $$$OK
}

ClassMethod GetSnapshot() As %Library.Status
{
    Try
    {
        #Dim %request As %CSP.Request
        #Dim %response As %CSP.Response
        Set method = ..GetMethodName("GetSnapshot")

        Set %response.ContentType = "application/json"
        Set %response.CharSet = "utf-8"

        // call specific setup method
        Write $CLASSMETHOD(##this, method, %request)
    }
    Catch (exception)
    {
        Write exception.DisplayString()
    }

    Return $$$OK
}

ClassMethod GetSnapshotGeneric(pRequest As %CSP.Request) As %Library.String
{
    Set snapshot = {}

    // do all queries, fill up return object and return
    Set snapshot.namespaceConfig = ..GetNamespaces()
    Set snapshot.tasks = ..GetTasks()
    Set snapshot.webApplications = ..GetWebApplications()
    Set snapshot.sqlConnections = ..GetSqlConnections()
    Set snapshot.users = ..GetUsers()
    Set snapshot.roles = ..GetRoles()
    Set snapshot.resources = ..GetResources()
    Set snapshot.ssl = ..GetSsl()
    Set snapshot.namespaces = []

    Set namespaceIterator = snapshot.namespaceConfig.%GetIterator()
    While namespaceIterator.%GetNext(.key, .value)
    {
        Set namespaceName = value.id

        If (namespaceName = "%SYS") Continue
        If (namespaceName = "HSCUSTOM") Continue
        If (namespaceName = "HSLIB") Continue
        If (namespaceName = "HSSYS") Continue
        If (namespaceName = "HSLOCALTEMP") Continue
        If (namespaceName = "ENSLIB") Continue
        If (namespaceName = "USER") Continue
        If (namespaceName = "ENSDEMO") Continue
        If (namespaceName = "ENSEMBLE") Continue
        If (namespaceName = "%ALL") Continue

        Try
        {
            ZNspace namespaceName
        }
        Catch (exception)
        {
            Continue
        }

        Set namespace = {}

        Set namespace.id = namespaceName

        Set namespace.classes = ..GetClasses()
        Set namespace.globals = ..GetGlobals()

        // Configs exclusive to interoperability enabled namespaces
        If (##class(%Library.EnsembleMgr).IsEnsembleNamespace())
        {
            Set namespace.credentials = ..GetCredentials()
            Set namespace.productionItems = ..GetProductionItems()
            Set namespace.lookups = ..GetLookups()
        }

        $$$ThrowOnError(snapshot.namespaces.%Push(namespace))
    }

    Return snapshot.%ToJSON()
}

ClassMethod SafeGet(pResult As %SQL.StatementResult, pColumnName As %Library.String) As %Library.String
{
    Try
    {
        Return pResult.%Get(pColumnName)
    }
    Catch (exception)
    {
        Return ""
    }
}

ClassMethod GetNamespaces() As %Library.DynamicObject
{
    Set sql = ##class(%SQL.Statement).%New()

    Set query = "SELECT * FROM Config.Namespaces_List()"

    $$$ThrowOnError(sql.%Prepare(query))

    Set result = sql.%Execute()

    Set response = []

    While result.%Next(.sc)
    {
        $$$ThrowOnError(sc)

        Set namespace = {}

        Set namespace.id = ..SafeGet(result, "Namespace")
        Set namespace.globals = ..SafeGet(result, "Globals")
        Set namespace.routines = ..SafeGet(result, "Routines")

        Do response.%Push(namespace)
    }

    Return response
}

ClassMethod GetTasks() As %Library.DynamicObject
{
    Set sql = ##class(%SQL.Statement).%New()

    Set query = "SELECT * FROM %SYS.Task WHERE Type = 2"

    $$$ThrowOnError(sql.%Prepare(query))

    Set result = sql.%Execute()

    Set response = []

    While result.%Next(.sc)
    {
        $$$ThrowOnError(sc)

        Set task = {}

        Set task.id = ..SafeGet(result, "Name")
        Set task.dailyEndTime = ..SafeGet(result, "DailyEndTime")
        Set task.dailyFrequency = ..SafeGet(result, "DailyFrequency")
        Set task.dailyFrequencyTime = ..SafeGet(result, "DailyFrequencyTime")
        Set task.dailyIncrement = ..SafeGet(result, "DailyIncrement")
        Set task.dailyStartTime = ..SafeGet(result, "DailyStartTime")
        Set task.deleteAfterRun = ..SafeGet(result, "DeleteAfterRun")
        Set task.description = ..SafeGet(result, "Description")
        Set task.expires = ..SafeGet(result, "Expires")
        Set task.expiresDays = ..SafeGet(result, "ExpiresDays")
        Set task.expiresHours = ..SafeGet(result, "ExpiresHours")
        Set task.expiresMinutes = ..SafeGet(result, "ExpiresMinutes")
        Set task.isBatch = ..SafeGet(result, "IsBatch")
        Set task.mirrorStatus = ..SafeGet(result, "MirrorStatus")
        Set task.nameSpace = ..SafeGet(result, "NameSpace")
        Set task.priority = ..SafeGet(result, "Priority")
        Set task.rescheduleOnStart = ..SafeGet(result, "RescheduleOnStart")
        Set task.runAsUser = ..SafeGet(result, "RunAsUser")
        Set task.suspendOnError = ..SafeGet(result, "SuspendOnError")
        Set task.suspendTerminated = ..SafeGet(result, "SuspendTerminated")
        Set task.suspended = ..SafeGet(result, "Suspended")
        Set task.taskClass = ..SafeGet(result, "TaskClass")
        Set task.timePeriod = ..SafeGet(result, "TimePeriod")
        Set task.timePeriodDay = ..SafeGet(result, "TimePeriodDay")
        Set task.timePeriodEvery = ..SafeGet(result, "TimePeriodEvery")
        Set task.type = ..SafeGet(result, "Type")

        Do response.%Push(task)
    }

    Return response
}

ClassMethod GetWebApplications() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM Security.Applications WHERE Type = 2"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set application = {}
    
            Set application.id = ..SafeGet(result, "ID")
            Set application.autheEnabled = ..SafeGet(result, "AutheEnabled")
            Set application.autoCompile = ..SafeGet(result, "AutoCompile")
            Set application.CSPZENEnabled = ..SafeGet(result, "CSPZENEnabled")
            Set application.description = ..SafeGet(result, "Description")
            Set application.dispatchClass = ..SafeGet(result, "DispatchClass")
            Set application.enabled = ..SafeGet(result, "Enabled")
            Set application.isNameSpaceDefault = ..SafeGet(result, "IsNameSpaceDefault")
            Set application.JWTAccessTokenTimeout = ..SafeGet(result, "JWTAccessTokenTimeout")
            Set application.JWTAuthEnabled = ..SafeGet(result, "JWTAuthEnabled")
            Set application.JWTRefreshTokenTimeout = ..SafeGet(result, "JWTRefreshTokenTimeout")
            Set application.name = ..SafeGet(result, "Name")
            Set application.nameLowerCase = ..SafeGet(result, "NameLowerCase")
            Set application.nameSpace = ..SafeGet(result, "NameSpace")
            Set application.resource = ..SafeGet(result, "Resource")
    
            Do response.%Push(application)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetSqlConnections() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM %Library.sys_SQLConnection"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set sqlConnection = {}
    
            Set sqlConnection.id = ..SafeGet(result, "Connection_Name")
            Set sqlConnection.URL = ..SafeGet(result, "URL")
            Set sqlConnection.usr = ..SafeGet(result, "Usr")
            Set sqlConnection.classpath = ..SafeGet(result, "classpath")
            Set sqlConnection.driver = ..SafeGet(result, "driver")
            Set sqlConnection.isJDBC = ..SafeGet(result, "isJDBC")
            Set sqlConnection.useCAST = ..SafeGet(result, "useCAST")
            Set sqlConnection.useCASTCHAR = ..SafeGet(result, "useCASTCHAR")
            Set sqlConnection.useCOALESCE = ..SafeGet(result, "useCOALESCE")
    
            Do response.%Push(sqlConnection)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetUsers() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM Security.Users"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set user = {}
    
            Set user.id = ..SafeGet(result, "ID")
            Set user.accountNeverExpires = ..SafeGet(result, "AccountNeverExpires")
            Set user.enabled = ..SafeGet(result, "Enabled")
            Set user.fullName = ..SafeGet(result, "FullName")
            Set user.name = ..SafeGet(result, "Name")
            Set user.nameLowerCase = ..SafeGet(result, "NameLowerCase")
            Set user.nameSpace = ..SafeGet(result, "NameSpace")
            Set user.roles = ..SafeGet(result, "Roles")
    
            Do response.%Push(user)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetRoles() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM Security.Roles"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set role = {}
    
            Set role.id = ..SafeGet(result, "ID")
            Set role.description = ..SafeGet(result, "Description")
            Set role.escalationOnly = ..SafeGet(result, "EscalationOnly")
            Set role.grantedRoles = ..SafeGet(result, "GrantedRoles")
            Set role.name = ..SafeGet(result, "Name")
            Set role.nameLowerCase = ..SafeGet(result, "NameLowerCase")
    
            Do response.%Push(role)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetResources() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM Security.Resources"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set resource = {}
    
            Set resource.id = ..SafeGet(result, "ID")
            Set resource.description = ..SafeGet(result, "Description")
            Set resource.name = ..SafeGet(result, "Name")
            Set resource.nameLowerCase = ..SafeGet(result, "NameLowerCase")
            Set resource.publicPermission = ..SafeGet(result, "PublicPermission")
            Set resource.type = ..SafeGet(result, "Type")
    
            Do response.%Push(resource)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetSsl() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM Security.SSLConfigs"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set ssl = {}
    
            Set ssl.id = ..SafeGet(result, "ID")
            Set ssl.cipherList = ..SafeGet(result, "CipherList")
            Set ssl.protocols = ..SafeGet(result, "Protocols")
            Set ssl.tLSMaxVersion = ..SafeGet(result, "TLSMaxVersion")
            Set ssl.tLSMinVersion = ..SafeGet(result, "TLSMinVersion")
            Set ssl.type = ..SafeGet(result, "Type")
            Set ssl.verifyDepth = ..SafeGet(result, "VerifyDepth")
            Set ssl.verifyPeer = ..SafeGet(result, "VerifyPeer")
    
            Do response.%Push(ssl)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetCredentials() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM Ens_Config.Credentials"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set credential = {}
    
            Set credential.id = ..SafeGet(result, "SystemName")
            Set credential.username = ..SafeGet(result, "Username")
    
            Do response.%Push(credential)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetClasses() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM %Library.RoutineMgr_StudioOpenDialog('*.cls',1,1,0,1,0,0)"
        Set query = query _ " WHERE Name NOT LIKE 'Ens.%'"
        Set query = query _ " AND Name NOT LIKE 'EnsLib.%'"
        Set query = query _ " AND Name NOT LIKE 'EnsPortal.%'"
        Set query = query _ " AND Name NOT LIKE 'CSPX.%'"
        Set query = query _ " AND Name NOT LIKE 'HS.%'"
        Set query = query _ " AND Name NOT LIKE 'HSMOD.%'"
        Set query = query _ " AND Name NOT LIKE 'SchemaMap.%'"
        Set query = query _ " AND Name NOT LIKE 'WebTerminal.%'"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            If ($SYSTEM.Status.IsError(sc))
            {
                Continue
            }
    
            Set class = {}
    
            Set class.id = ..SafeGet(result, "Name")
            Set class.type = ..SafeGet(result, "Type")
    
            Do response.%Push(class)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetGlobals() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM %SYS.GlobalQuery_NameSpaceList()"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set global = {}
    
            Set global.id = ..SafeGet(result, "Name")
            Set global.resourceName = ..SafeGet(result, "ResourceName")
            Set global.permission = ..SafeGet(result, "Permission")
            Set global.empty = ..SafeGet(result, "Empty")
            Set global.keep = ..SafeGet(result, "Keep")
            Set global.collation = ..SafeGet(result, "Collation")
            Set global.hasData = ..SafeGet(result, "HasData")
    
            Do response.%Push(global)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetProductionItems() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set currentProduction = ##class(Ens.Director).GetActiveProductionName()
    
        Set query = "SELECT * FROM Ens_Config.Item WHERE Production = ?"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute(currentProduction)
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set productionItem = {}
    
            Set productionItem.id = ..SafeGet(result, "Name")
            Set productionItem.alertGroups = ..SafeGet(result, "AlertGroups")
            Set productionItem.category = ..SafeGet(result, "Category")
            Set productionItem.className = ..SafeGet(result, "ClassName")
            Set productionItem.comment = ..SafeGet(result, "Comment")
            Set productionItem.disableErrorTraps = ..SafeGet(result, "DisableErrorTraps")
            Set productionItem.foreground = ..SafeGet(result, "Foreground")
            Set productionItem.logTraceEvents = ..SafeGet(result, "LogTraceEvents")
            Set productionItem.poolSize = ..SafeGet(result, "PoolSize")
            Set productionItem.production = ..SafeGet(result, "Production")
            Set productionItem.schedule = ..SafeGet(result, "Schedule")
            Set productionItem.settings = ..SafeGet(result, "Settings")
    
            Do response.%Push(productionItem)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

ClassMethod GetLookups() As %Library.DynamicObject
{
    Try
    {
        Set sql = ##class(%SQL.Statement).%New()
    
        Set query = "SELECT * FROM Ens_Util.LookupTable"
    
        $$$ThrowOnError(sql.%Prepare(query))
    
        Set result = sql.%Execute()
    
        Set response = []
    
        While result.%Next(.sc)
        {
            $$$ThrowOnError(sc)
    
            Set lookup = {}
    
            Set lookup.dataValue = ..SafeGet(result, "DataValue")
            Set lookup.keyName = ..SafeGet(result, "KeyName")
            Set lookup.tableName = ..SafeGet(result, "TableName")
    
            Do response.%Push(lookup)
        }
    
        Return response
    }
    Catch (exception)
    {
        Return []
    }
}

}
