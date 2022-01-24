**free
//=== US Address Validation Data Structure Parm template =============
dcl-ds USAdrValDS template qualified;
    Address1    char(30);
    Address2    char(30);
    City        char(30);
    State       char(2);
    Zip5        char(5);
    Zip4        char(4);
    Number      int(10);        // Error Number
    Source      varchar(30);    // Error Source
    Description varchar(512);   // Error Description
end-ds;
// === End of US Address Validation Data Structure Parm template =====
