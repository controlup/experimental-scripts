# TInfo: Peter Nap

#Update item on the board:
function Set-MondayColumnValue {
    #Example usage: Set-MondayColumnValue -boardID 1234 -itemID $itemID -newValue $(Get-Date).ToString("dd-MM-yyyy HH:mm:ss") -cName "text05"
    param (
        $boardID,
        $itemID,
        $newValue,
        $cName
    )
    $key="<key>"

    $url = "https://api.monday.com/v2/"
    $hdr = @{}
    $hdr.Add("Authorization" , "$key")
    $hdr.Add("Content-Type","application/json")

    # set board ID
    

    $query = 'mutation($board:Int!, $item:Int!, $col:String!, $vals:String!) {change_simple_column_value(board_id:$board, item_id:$item, column_id: $col, value: $vals) {id} }'
    $vars = @{'board' = $boardID; 'item' = $itemID; 'col' = $cName; 'vals' = $newValue}
    $vars.vals

    # create request from "query" and "vars" and make API call
    $req = @{query = $query; variables = $vars}
    $bodytxt = $req | ConvertTo-Json


    # create request from "query" and "vars" and make API call

    $response  = Invoke-WebRequest -Uri $url -Headers $hdr -Method Post -body $bodytxt
    return $response

}

function Get-MondayBoardItems {
    #Example usage: Get-MondayBoardItems -boardID 1234 -itemID 1234
    param (
        $boardID
    )
    $key="<key>"

    $url = "https://api.monday.com/v2/"
    $hdr = @{}
    $hdr.Add("Authorization" , "$key")
    $hdr.Add("Content-Type","application/json")
    # query to get items on board 
    #{ boards (ids: 000000000) { items { id name column_values { id title value } } }
    $query = 'query($boardId: Int!){boards(ids:[$boardId]) { items { id name column_values {id title value} } } }'
    $vars = @{'boardId'= $boardID}

    # create request object with "query" and "vars" and serialize into JSON
    $req = @{query = $query; variables = $vars}
    $bodytxt = $req | ConvertTo-Json
    $response  = Invoke-WebRequest -Uri $url -Headers $hdr -Method Post -body $bodytxt

    # declare data structures to store column IDs and types
    $responseData = ($response.content | ConvertFrom-Json)
    #$responseData.data.boards.items # list of items on board

    $responseData.data.boards.items 
    
}

#Examples
Get-MondayBoardItems -boardID 1234

Set-MondayColumnValue -boardID 1234 -itemID $itemID -newValue "Running" -cName "text3"
Set-MondayColumnValue -boardID 1234 -itemID $itemID -newValue $(Get-Date).ToString("dd-MM-yyyy HH:mm:ss") -cName "text05"
