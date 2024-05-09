**free
//==============================================================
//=== USADRVAL: Service program to validate and standardize
//=== a USA address.
//=== Calls the USPS webtools API AddressValidateRequest.
//====================================================================
// See US Postal Service documentation:
// www.usps.com/business/web-tools-apis/address-information-api.htm#_Toc39492052
// www.usps.com/business/web-tools-apis/general-api-developer-guide.htm
//====================================================================
// CRTRPGMOD MODULE(USADRVAL)
// CRTSRVPGM SRVPGM(USADRVAL) EXPORT(*ALL)
// CRTBNDDIR BNDDIR(ADRVAL_BND) TEXT('Address Validation Binding Dir')
// ADDBNDDIRE BNDDIR(ADRVAL_BND) OBJ((USADRVAL *SRVPGM *DEFER))
// CRTDTAARA DTAARA(USPS_ID) TYPE(*CHAR) LEN(20) VALUE(your user id)
//====================================================================
// Input address information is passed in a data structure.
// The standardized address is returned, also in a data structure.
// For ease of use, the same data structure layout is used for
// input and output, but it doesn't have to be the same memory
// in the caller. Use copy member USAdrValDS.
//====================================================================
// 04/2024 LENNON
//  Change to HTTPS
//  Provide password, even though it currently seems to be ignored. 
//====================================================================

ctl-opt
    nomain
    bnddir('SQL_BND')
    option(*nodebugio: *srcstmt)
;
//=== Prototypes =====================================================
/copy ../Copy_Mbrs/SRV_SQL_P.RPGLE

//=== Parameter Data Structure Template ==============================
/copy ../Copy_Mbrs/USADRVALDS.RPGLE

// === Data area containing your USPS supplied User id. ==============
// (The USPS supplied USER ID length is not clear, so I made it
// longer than the 12-char one supplied to me..)
// Ditto for password, though password seems to be ignored.
dcl-ds USPS_ID    dtaara  len(20) qualified;
end-ds;
dcl-ds USPS_PWD   dtaara  len(20) qualified;
end-ds;

//=== USAdrVal =======================================================
dcl-proc USAdrVal   export;
  dcl-pi USAdrVal likeds(USAdrValDS);
    pi likeds   (USAdrValDS);
  end-pi;

  dcl-c SQLSUCCESS       '00000';
  dcl-c SQLNODATA        '02000';

  // XML returned from the USPS API
  dcl-s retXML     char(2048) ccsid(*UTF8);

  // Returned outparm data structure
  dcl-ds  po  likeds(USAdrValDS);

  dcl-s ID        varchar(20);
  dcl-s PWD       varchar(20);
  // Get USPS UserID & Password
  in USPS_ID;
  ID = %trim(USPS_ID);
  in USPS_PWD;
  PWD = %trim(USPS_PWD);

  clear po;

  // Call USPS Address Validate API. It returns an XML document.
  exec sql
    values  QSYS2.HTTP_GET(
      'https://secure.shippingapis.com/ShippingAPI.dll'
      concat '?API=Verify&XML=' concat
      url_encode(
        '<AddressValidateRequest ' concat
        'USERID="' concat :ID concat '"' 
          concat ' PASSWORD="' concat :PWD concat '">' concat
        '<Revision>1</Revision>' concat
        '<Address ID="0">' concat
            '<Address1>' concat :pi.Address1 concat '</Address1>' concat
            '<Address2>' concat :pi.Address2 concat '</Address2>' concat
            '<City>' concat :pi.City concat '</City>' concat
            '<State>' concat :pi.State concat '</State>' concat
            '<Zip5>' concat :pi.Zip5 concat  '</Zip5>' concat
            '<Zip4>' concat :pi.Zip4 concat '</Zip4>' concat
        '</Address>' concat
        '</AddressValidateRequest>'
      )
    ) into :retXML;
  if (SQLSTATE <> SQLSUCCESS);
    SQLProblem('USPS API Call');
  endif;

  // Parse the XML document into program variables. Even if the API
  // returns an error the SQL should not fail since defaults are set
  exec sql
    select x.* into :po.Address1, :po.Address2, :po.City,
                    :po.State, :po.Zip5, :po.Zip4
    from xmltable
    ('AddressValidateResponse/Address'
        passing xmlparse(document  :retXML)
        columns
            Address1    char(30)    path 'Address1' default ' ',
            Address2    char(30)    path 'Address2' default ' ',
            City        Char(30)    path 'City' default ' ',
            State       char(2)     path 'State' default ' ',
            zip5        char(5)     path 'Zip5' default ' ',
            Zip4        char(4)     path 'Zip4' default ' '
    ) as x;
  if (SQLSTATE <> SQLSUCCESS);
    SQLProblem('XMLPARSE of Addr');
  endif;

  //  If a city was returned, assume it worked.
  if (po.City <> ' ');
    return po;
  endif;

  // If no city, then parse the error XML
  exec SQL
    select x.* into :po.Number, :po.Source, :po.Description
    from xmltable
    ('AddressValidateResponse/Address/Error'
        passing xmlparse(document  :retXML)
        columns
            Number      integer         path 'Number',
            Source      char(30)        path 'Source',
            Description varChar(512)    path 'Description'
    ) as x;
  if (SQLSTATE <> SQLSUCCESS);
    SQLProblem('XMLPARSE of Error');
  endif;
  return po;

end-proc USAdrVal;
