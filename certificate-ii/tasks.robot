*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Archive
Library             RPA.Excel.Files
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault
# https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Descargar el csv
    ${orders}=    Get orders

    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    5x    0.5 sec    Preview the robot
        Wait Until Keyword Succeeds    5x    0.5 sec    Submit the order
        Store the receipt as a PDF file    ${row}
        Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${row}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Log out and close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK

Collect search query from user
    Add text input    search    label=Search query
    ${response}=    Run dialog
    RETURN    ${response.search}

Descargar el csv
    ${response}=    Collect search query from user
    Download    ${response}    overwrite=True

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Get orders
    ${table}=    Read table from CSV    orders.csv    header=True
    Log    Found columns: ${table.columns}
    RETURN    ${table}

Store the receipt as a PDF file
    [Arguments]    ${row}
    Set Local Variable    ${order_id}    ${row}[Order number]
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}temporalPDF${/}receipt_${order_id}.pdf
    Wait Until Element Is Visible    id:robot-preview-image

Take a screenshot of the robot
    [Arguments]    ${row}
    Set Local Variable    ${order_id}    ${row}[Order number]
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}temporalPNG${/}robot_${order_id}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    Set Local Variable    ${order_id}    ${row}[Order number]
    Set Local Variable    ${filename_pdf}    ${OUTPUT_DIR}${/}temporalPDF${/}receipt_${order_id}.pdf
    Set Local Variable    ${filename_photo}    ${OUTPUT_DIR}${/}temporalPNG${/}robot_${order_id}.png
    Open PDF    ${filename_pdf}
    @{pseudo_file_list}=    Create List
    ...    ${filename_pdf}
    ...    ${filename_photo}:align=center

    Add Files To PDF    ${pseudo_file_list}    ${filename_pdf}    ${False}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/orders.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}temporalPDF${/}
    ...    ${zip_file_name}

Log out and close the browser
    Close Browser
