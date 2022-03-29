// This file contains your Data Connector logic
section LoginEnterprise;

[DataSource.Kind="LoginEnterprise", Publish="LoginEnterprise.Publish"]
shared LoginEnterprise.apiURL = Value.ReplaceType(LoginEnterpriseImpl, type function (url as Uri.Type) as any);


token = Extension.CurrentCredential()[Key];

LoginEnterpriseImpl = (url as text) =>
    let
                Tests = Json.Document(Web.Contents(url, [RelativePath="tests", Query=[
                        orderBy="name", 
                        direction="ascending",
                        count="100",
                        include="none",
                        token=token
                    ]])),
                items = Tests[items],
    
                #"Tests Convert" = Table.FromList(items, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
                #"Tests Expand" = Table.ExpandRecordColumn(#"Tests Convert", "Column1", 
                    {"$type", "scheduleType", "scheduleIntervalInMinutes", "numberOfSessions", "takeScriptScreenshots", "repeatCount", "isRepeatEnabled", "isEnabled", "restartOnComplete", "alertConfigurations", "id", "name", "description", "created", "environment", "workload", "rampUpDurationInMinutes", "testDurationInMinutes", "rampDownDurationInMinutes", "state"}, 
                    {"testType", "testScheduleType", "testScheduleIntervalInMinutes", "testNumberOfSessions", "testTakeScriptScreenshots", "testRepeatCount", "testIsRepeatEnabled", "testIsEnabled", "testRestartOnComplete", "testAlertConfigurations", "testId", "testName", "testDescription", "testCreated", "testEnvironment", "testWorkload", "testRampUpDurationInMinutes", "testDurationInMinutes", "testRampDownDurationInMinutes", "testState"}),

                #"TestRun Invoke" = Table.AddColumn(#"Tests Expand", "TestRun", each TestRun(url,[testId])),
                #"TestRun Expand" = Table.ExpandTableColumn(#"TestRun Invoke", "TestRun", {"Column1"}, {"Column1"}),
                #"TestRun Expand Columns" = Table.ExpandRecordColumn(#"TestRun Expand", "Column1", 
                    {"state", "result", "appFailureResults", "appPerformanceResults", "properties", "id", "created", "started", "finished", "counter"}, 
                    {"testRunState", "testRunResult", "testRunAppFailureResults", "testRunAppPerformanceResults", "testRunProperties", "testRunId", "testRunCreated", "testRunStarted", "testRunFinished", "testRunCounter"}),
                #"TestRun Expanded appFailureResults" = Table.ExpandRecordColumn(#"TestRun Expand Columns", "testRunAppFailureResults", {"successCount", "totalCount"}, {"testRunAppFailureResults.successCount", "testRunAppFailureResults.totalCount"}),
                #"TestRun Expanded appPerformanceResults" = Table.ExpandRecordColumn(#"TestRun Expanded appFailureResults", "testRunAppPerformanceResults", {"successCount", "totalCount"}, {"testRunAppPerformanceResults.successCount", "testRunAppPerformanceResults.totalCount"}),
    
                #"Measurement Invoke" = Table.AddColumn(#"TestRun Expanded appPerformanceResults", "Measurements", each Measurement(url,[testRunId])),
                #"Measurements Expand" = Table.ExpandRecordColumn(#"Measurement Invoke", "Measurements", {"items"}, {"items"}),
                #"Measurements Expand Columns" = Table.ExpandListColumn(#"Measurements Expand", "items"),
                #"Measurements Expand to Rows" = Table.ExpandRecordColumn(#"Measurements Expand Columns", "items", 
                    {"measurementId", "appExecutionId", "applicationId", "launcherName", "accountId", "userSessionId", "duration", "timestamp", "properties"}, 
                    {"measurementId", "measurementAppExecutionId", "measurementApplicationId", "measurementLauncherName", "measurementAccountId", "measurementUserSessionId", "measurementDuration", "measurementTimestamp", "measurementProperties"}),
                #"Removed Duplicates" = Table.Distinct(#"Measurements Expand to Rows", {"measurementTimestamp"}),
    
                #"Application Invoke" = Table.AddColumn(#"Measurements Expand to Rows", "Applications", each Application(url,[measurementApplicationId])),
                #"Applications Expand" = Table.ExpandRecordColumn(#"Application Invoke", "Applications", 
                    {"$type", "commandLine", "workingDirectory", "mainWindowTitle", "mainProcessName", "id", "name", "description", "userName", "created", "lastModified", "script", "timers"}, 
                    {"applicationType", "applicationCommandLine", "applicationWorkingDirectory", "applicationMainWindowTitle", "applicationMainProcessName", "applicationId", "applicationName", "applicationDescription", "applicationUserName", "applicationCreated", "applicationLastModified", "applicationScript", "applicationTimers"}),
                #"Application Timers Expand" = Table.ExpandListColumn(#"Applications Expand", "applicationTimers"),
    
                #"TestRunEvent Invoke" = Table.AddColumn(#"Application Timers Expand", "TestRunEvents", each TestRunEvent(url,[testRunId])),
                #"TestRunEvents Expand" = Table.ExpandRecordColumn(#"TestRunEvent Invoke", "TestRunEvents", {"items"}, {"items"}),
                #"TestRunEvents Expand Rows" = Table.ExpandListColumn(#"TestRunEvents Expand", "items"),
                #"TestRunEvents Expand Items" = Table.ExpandRecordColumn(#"TestRunEvents Expand Rows", "items", 
                    { "eventType", "title"}, 
                    {"testRunEventType", "testRunEventTitle"}),
    
    
                #"Results" = Table.TransformColumnTypes(#"TestRunEvents Expand Items",{{"testType", type text}, {"testScheduleType", type text}, {"testScheduleIntervalInMinutes", Int64.Type}, {"testNumberOfSessions", Int64.Type}, {"testTakeScriptScreenshots", type text}, {"testCreated", type datetimezone}, {"testRampUpDurationInMinutes", Int64.Type}, {"testDurationInMinutes", Int64.Type}, {"testRampDownDurationInMinutes", Int64.Type}, {"testRunAppFailureResults.successCount", Int64.Type}, {"testRunAppFailureResults.totalCount", Int64.Type}, {"testRunAppPerformanceResults.successCount", Int64.Type}, {"testRunAppPerformanceResults.totalCount", Int64.Type}, {"testRunCreated", type datetimezone}, {"testRunStarted", type datetimezone}, {"testRunFinished", type datetimezone}, {"testRunCounter", Int64.Type}, {"measurementDuration", Int64.Type}, {"measurementTimestamp", type datetimezone}, {"applicationCreated", type datetimezone}, {"applicationLastModified", type datetimezone}})
    in
        #"Results";



TestRun = (url as text, testRunId as text) =>
try
    let
            TestRuns = Json.Document(Web.Contents(url, [RelativePath="/tests/" & testRunId &"/test-runs", Query=[
            direction="ascending", 
            count="50",
            include="none",
            token=token
            ]])),
            items2 = TestRuns[items],
            #"ConvertedTestRuns" = Table.FromList(items2, Splitter.SplitByNothing(), null, null, ExtraValues.Error)    
    in
        #"ConvertedTestRuns"
otherwise null;

Measurement = (url as text, testRunID as text) =>
try
    let
        Measurements = Json.Document(Web.Contents(url, [RelativePath="/test-runs/" & testRunID & "/measurements", Query=[
                    direction="ascending", 
                    count="50",
                    include="all",
                    token= token
                ]]))
    in
        Measurements
otherwise null;

Application = (url as text, applicationID as any) =>
try
let
    ApplicationDetails = Json.Document(Web.Contents(url, [RelativePath="/applications/" & applicationID & "/", Query=[
                include="all",
                token=token
            ]]))
in
    ApplicationDetails
otherwise null;

TestRunEvent = (url as text, TestRunID as any) =>
try
let
    TestRunEvents = Json.Document(Web.Contents(url, [RelativePath="/test-runs/" & TestRunID & "/events", Query=[
                count="100",
                include="all",
                token=token
            ]]))
in
    TestRunEvents
otherwise null;



// Data Source Kind description
LoginEnterprise = [
    // enable both OAuth and Key based auth
    Authentication = [
        Key = [
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
LoginEnterprise.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText =  { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://www.loginvsi.com/",
    SourceImage = LoginEnterprise.Icons,
    SourceTypeImage = LoginEnterprise.Icons
];


LoginEnterprise.Icons = [
Icon16 = { Extension.Contents("LoginEnterprise16.png") ,Extension.Contents("LoginEnterprise20.png") ,Extension.Contents("LoginEnterprise24.png") ,Extension.Contents("LoginEnterprise32.png") },
Icon32 = { Extension.Contents("LoginEnterprise32.png") ,Extension.Contents("LoginEnterprise40.png") ,Extension.Contents("LoginEnterprise48.png") ,Extension.Contents("LoginEnterprise64.png") }
];
