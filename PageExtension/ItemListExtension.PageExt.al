pageextension 50101 "Item List Extension" extends "Item List"
{
    actions
    {
        addfirst(Processing)
        {
            action(Gallery)
            {
                ApplicationArea = all;
                Image = Picture;
                ToolTip = 'Opens Gallery for the Item.';

                trigger OnAction()
                var
                    GDIMediaMgt: Codeunit "GDI Media Mgt.";
                begin
                    GDIMediaMgt.RunMediaPage(Database::Item, Rec."No.", Rec.TableCaption + ' ' + Rec."No.");
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(Gallery_ref; Gallery)
            {
            }
        }
    }
}