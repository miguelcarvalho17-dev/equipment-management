namespace MiguelCarvalho.EquipmentManagement;

report 50103 "EQM Usage Analytics"
{
    Caption = 'Usage Analytics';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    AdditionalSearchTerms = 'usage analytics, most assigned categories, maintenance trends, equipment growth, active users, statistics';
    DefaultRenderingLayout = UsageAnalyticsExcel;
    ExcelLayoutMultipleDataSheets = true;

    dataset
    {
        dataitem(MostAssignedCategories; "EQM Usage Analytics Buffer")
        {
            DataItemTableView = sorting("Line No.");

            column(CategoryRank; Rank)
            {
                IncludeCaption = true;
            }
            column(CategoryCode; "Category Code")
            {
                IncludeCaption = true;
            }
            column(CategoryDescription; "Category Description")
            {
                IncludeCaption = true;
            }
            column(NoOfAssignments; "No. of Assignments")
            {
                IncludeCaption = true;
            }
            column(AssignmentSharePct; "Assignment Share %")
            {
                IncludeCaption = true;
            }

            trigger OnPreDataItem()
            begin
                UsageAnalyticsMgt.BuildMostAssignedCategories(MostAssignedCategories, StartingDate, EndingDate);
            end;
        }
        dataitem(MaintenanceTrends; "EQM Usage Analytics Buffer")
        {
            DataItemTableView = sorting("Line No.");

            column(TrendPeriodStart; "Period Start Date")
            {
                IncludeCaption = true;
            }
            column(TrendPeriodEnd; "Period End Date")
            {
                IncludeCaption = true;
            }
            column(NoOfMaintenances; "No. of Maintenances")
            {
                IncludeCaption = true;
            }
            column(MaintenanceCost; "Maintenance Cost")
            {
                IncludeCaption = true;
            }

            trigger OnPreDataItem()
            begin
                UsageAnalyticsMgt.BuildMaintenanceTrends(MaintenanceTrends, StartingDate, EndingDate);
            end;
        }
        dataitem(EquipmentGrowth; "EQM Usage Analytics Buffer")
        {
            DataItemTableView = sorting("Line No.");

            column(GrowthPeriodStart; "Period Start Date")
            {
                IncludeCaption = true;
            }
            column(GrowthPeriodEnd; "Period End Date")
            {
                IncludeCaption = true;
            }
            column(NewEquipment; "New Equipment")
            {
                IncludeCaption = true;
            }
            column(TotalEquipment; "Total Equipment")
            {
                IncludeCaption = true;
            }

            trigger OnPreDataItem()
            begin
                UsageAnalyticsMgt.BuildEquipmentGrowth(EquipmentGrowth, StartingDate, EndingDate);
            end;
        }
        dataitem(ActiveUsers; "EQM Usage Analytics Buffer")
        {
            DataItemTableView = sorting("Line No.");

            column(UsersPeriodStart; "Period Start Date")
            {
                IncludeCaption = true;
            }
            column(UsersPeriodEnd; "Period End Date")
            {
                IncludeCaption = true;
            }
            column(ActiveUsersCount; "Active Users")
            {
                IncludeCaption = true;
            }

            trigger OnPreDataItem()
            begin
                UsageAnalyticsMgt.BuildActiveUsers(ActiveUsers, StartingDate, EndingDate);
            end;
        }
    }

    requestpage
    {
        SaveValues = false;

        layout
        {
            area(Content)
            {
                group(Period)
                {
                    Caption = 'Period';

                    field(StartingDateField; StartingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first day of the period that the statistics cover. The default is the first day of the month 11 months before the work date, so that the period is 12 calendar months. The period can be at most 120 months.';
                    }
                    field(EndingDateField; EndingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last day of the period that the statistics cover. The default is the work date. It cannot be before the starting date.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout(UsageAnalyticsExcel)
        {
            Type = Excel;
            LayoutFile = './src/Reports/Layouts/EQMUsageAnalytics.xlsx';
            Caption = 'Usage Analytics (Excel)';
            Summary = 'Shows operational statistics for a period in an Excel workbook with one sheet per metric: the most assigned equipment categories, the number and cost of posted maintenances per month, the growth of the equipment register per month, and the number of active users per month. Open maintenance records are not included and no user names are shown.';
        }
    }

    var
        UsageAnalyticsMgt: Codeunit "EQM Usage Analytics Mgt.";
        StartingDate: Date;
        EndingDate: Date;

    trigger OnInitReport()
    begin
        if (StartingDate = 0D) and (EndingDate = 0D) then
            UsageAnalyticsMgt.GetDefaultPeriod(0D, StartingDate, EndingDate);
    end;

    trigger OnPreReport()
    begin
        UsageAnalyticsMgt.CheckPeriod(StartingDate, EndingDate);
    end;

    /// <summary>
    /// Sets the period before the report runs, for callers that run the report without the request page.
    /// </summary>
    /// <param name="NewStartingDate">The first day of the period.</param>
    /// <param name="NewEndingDate">The last day of the period.</param>
    internal procedure SetPeriod(NewStartingDate: Date; NewEndingDate: Date)
    begin
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
    end;
}
