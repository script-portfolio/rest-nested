
# REST Server

## Task:

Write application to save comments to article. Comment on comments available too.
The application must support REST protocol and be able to handle below queries:

    1. Add comment
    2. Delete comment by id.
    3. Get list of all comments for article by id as json format. ( Child comments must by nest in parent comment ).

## Demo steps:

    I used Mojolicious engine to fast create application
    
    http://code-tricks.com/build-a-simple-restful-api-using-mojolicious/

### independent shell session
    morbo p.pl

### Presentation
    bash ./batch

### Presentation output

vlad@moon3 ~/src/rest-developex $ bash ./batch  
COMMAND: echo 'Initial record'  | curl -s --data @-  -X POST http://localhost:3000/
OUTPUT : SubComment inserted [id=1]

COMMAND: echo 'Second record'  | curl -s --data @-  -X POST http://localhost:3000/
OUTPUT : SubComment inserted [id=2]

COMMAND: echo 'Third record'  | curl -s --data @-  -X POST http://localhost:3000/
OUTPUT : SubComment inserted [id=3]

COMMAND: echo 'First subcomment for second record'  | curl -s --data @-  -X POST http://localhost:3000/2
OUTPUT : Comment inserted [id=4]

COMMAND: echo 'First subcomment for third record'  | curl -s --data @-  -X POST http://localhost:3000/3
OUTPUT : Comment inserted [id=5]

COMMAND: echo 'One more subcomment for second record'  | curl -s --data @-  -X POST http://localhost:3000/2
OUTPUT : Comment inserted [id=6]

COMMAND: echo 'Dive to subcomments for record 2'  | curl -s --data @-  -X POST http://localhost:3000/4
OUTPUT : Comment inserted [id=7]

COMMAND: echo 'Future dive to subcomments for record 2'  | curl -s --data @-  -X POST http://localhost:3000/7
OUTPUT : Comment inserted [id=8]

COMMAND: echo 'Parallel level for subcomments for record 2->4 ..'  | curl -s --data @-  -X POST http://localhost:3000/4
OUTPUT : Comment inserted [id=9]

TITLE  : Plain structure through DB:
COMMAND: sqlite3 -header -column dbcomment.sqlite '.read show.sql'
OUTPUT : id    id0   body                                                            
OUTPUT : ----  ----  ----------------------------------------------------------------
OUTPUT : 1     0     Initial record                                                  
OUTPUT : 2     0     Second record                                                   
OUTPUT : 3     0     Third record                                                    
OUTPUT : 4     2     First subcomment for second record                              
OUTPUT : 5     3     First subcomment for third record                               
OUTPUT : 6     2     One more subcomment for second record                           
OUTPUT : 7     4     Dive to subcomments for record 2                                
OUTPUT : 8     7     Future dive to subcomments for record 2                         
OUTPUT : 9     4     Parallel level for subcomments for record 2->4 ..               
OUTPUT : 


TITLE  : Comment list. Human readable for subcomment branch 4 (toplevel:2)
COMMAND: curl -s -X GET http://localhost:3000/4?format=text
OUTPUT : $VAR1 = {
OUTPUT :           '4' => {
OUTPUT :                  'body' => 'First subcomment for second record',
OUTPUT :                  'subc' => [
OUTPUT :                              {
OUTPUT :                                '7' => {
OUTPUT :                                         'body' => 'Dive to subcomments for record 2',
OUTPUT :                                         'subc' => [
OUTPUT :                                                     {
OUTPUT :                                                       '8' => {
OUTPUT :                                                                'body' => 'Future dive to subcomments for record 2'
OUTPUT :                                                              }
OUTPUT :                                                     }
OUTPUT :                                                   ]
OUTPUT :                                       }
OUTPUT :                              },
OUTPUT :                              {
OUTPUT :                                '9' => {
OUTPUT :                                         'body' => 'Parallel level for subcomments for record 2->4 ..'
OUTPUT :                                       }
OUTPUT :                              }
OUTPUT :                            ]
OUTPUT :                }
OUTPUT :         };


TITLE  : Comment list. Human readable for comment 2
COMMAND: curl -s -X GET http://localhost:3000/2?format=text
OUTPUT : $VAR1 = {
OUTPUT :           '2' => {
OUTPUT :                  'body' => 'Second record',
OUTPUT :                  'subc' => [
OUTPUT :                              {
OUTPUT :                                '6' => {
OUTPUT :                                         'body' => 'One more subcomment for second record'
OUTPUT :                                       }
OUTPUT :                              },
OUTPUT :                              {
OUTPUT :                                '4' => {
OUTPUT :                                         'body' => 'First subcomment for second record',
OUTPUT :                                         'subc' => [
OUTPUT :                                                     {
OUTPUT :                                                       '7' => {
OUTPUT :                                                                'body' => 'Dive to subcomments for record 2',
OUTPUT :                                                                'subc' => [
OUTPUT :                                                                            {
OUTPUT :                                                                              '8' => {
OUTPUT :                                                                                       'body' => 'Future dive to subcomments for record 2'
OUTPUT :                                                                                     }
OUTPUT :                                                                            }
OUTPUT :                                                                          ]
OUTPUT :                                                              }
OUTPUT :                                                     },
OUTPUT :                                                     {
OUTPUT :                                                       '9' => {
OUTPUT :                                                                'body' => 'Parallel level for subcomments for record 2->4 ..'
OUTPUT :                                                              }
OUTPUT :                                                     }
OUTPUT :                                                   ]
OUTPUT :                                       }
OUTPUT :                              }
OUTPUT :                            ]
OUTPUT :                }
OUTPUT :         };


TITLE  : Comment list. JSON for comment 2
COMMAND: curl -s -X GET http://localhost:3000/2
OUTPUT : {"2":{"body":"Second record","subc":[{"6":{"body":"One more subcomment for second record"}},{"4":{"body":"First subcomment for second record","subc":[{"7":{"body":"Dive to subcomments for record 2","subc":[{"8":{"body":"Future dive to subcomments for record 2"}}]}},{"9":{"body":"Parallel level for subcomments for record 2->4 .."}}]}}]}}

TITLE  : Delete single record. id=8
COMMAND: curl -s -X DELETE http://localhost:3000/8
OUTPUT : Deleted: 8

TITLE  : Plain structure through DB (after partial deletion):
COMMAND: sqlite3 -header -column dbcomment.sqlite '.read show.sql'
OUTPUT : id    id0   body                                                            
OUTPUT : ----  ----  ----------------------------------------------------------------
OUTPUT : 1     0     Initial record                                                  
OUTPUT : 2     0     Second record                                                   
OUTPUT : 3     0     Third record                                                    
OUTPUT : 4     2     First subcomment for second record                              
OUTPUT : 5     3     First subcomment for third record                               
OUTPUT : 6     2     One more subcomment for second record                           
OUTPUT : 7     4     Dive to subcomments for record 2                                
OUTPUT : 9     4     Parallel level for subcomments for record 2->4 ..               
OUTPUT : 


TITLE  : Partial recursive deletion
COMMAND: curl -s -X DELETE http://localhost:3000/4
OUTPUT : Deleted: 7,9,4

TITLE  : Comment list. Human readable for comment 2 (after deletion)
COMMAND: curl -s -X GET http://localhost:3000/2?format=text
OUTPUT : $VAR1 = {
OUTPUT :           '2' => {
OUTPUT :                  'body' => 'Second record',
OUTPUT :                  'subc' => [
OUTPUT :                              {
OUTPUT :                                '6' => {
OUTPUT :                                         'body' => 'One more subcomment for second record'
OUTPUT :                                       }
OUTPUT :                              }
OUTPUT :                            ]
OUTPUT :                }
OUTPUT :         };
vlad@moon3 ~/src/rest-developex $

