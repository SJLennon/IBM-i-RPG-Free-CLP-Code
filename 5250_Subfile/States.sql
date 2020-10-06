-- Build table of US State code and names
-- RUNSQLSTM SRCSTMF(states.sql) COMMIT(*NONE) ERRLVL(40)
set schema lennons1;
drop table states;
CREATE TABLE STATES ( 
	STATE CHAR(2) CCSID 273 NOT NULL , 
	NAME CHAR(30) CCSID 273 NOT NULL , 
	CONSTRAINT state_primary_key PRIMARY KEY( STATE ) )   
	  
	RCDFMT STATESF     ; 
  
ALTER TABLE STATES 
	ADD CONSTRAINT state_name_unique 
	UNIQUE( NAME ) ; 
  
LABEL ON TABLE STATES 
	IS 'US States' ; 

 INSERT into states values 
('AA', 'Armed Forces America'),
('AE', 'Armed Forces'),
('AK', 'Alaska'),
('AL', 'Alabama'),
('AS', 'American Samoa'),
('AZ', 'Arizona'),
('AR', 'Arkansas'),
('CA', 'California'),
('CO', 'Colorado'),
('CT', 'Connecticut'),
('DE', 'Delaware'),
('DC', 'District of Columbia'),
('FL', 'Florida'),
('GA', 'Georgia'),
('GU', 'Guam'),
('HI', 'Hawaii'),
('ID', 'Idaho'),
('IL', 'Illinois'),
('IN', 'Indiana'),
('IA', 'Iowa'),
('KS', 'Kansas'),
('KY', 'Kentucky'),
('LA', 'Louisiana'),
('ME', 'Maine'),
('MD', 'Maryland'),
('MA', 'Massachusetts'),
('MI', 'Michigan'),
('MN', 'Minnesota'),
('MP', 'Northern Mariana Islands'),
('MS', 'Mississippi'),
('MO', 'Missouri'),
('MT', 'Montana'),
('NE', 'Nebraska'),
('NV', 'Nevada'),
('NH', 'New Hampshire'),
('NJ', 'New Jersey'),
('NM', 'New Mexico'),
('NY', 'New York'),
('NC', 'North Carolina'),
('ND', 'North Dakota'),
('OH', 'Ohio'),
('OK', 'Oklahoma'),
('OR', 'Oregon'),
('PA', 'Pennsylvania'),
('PR', 'Puerto Rico'),
('RI', 'Rhode Island'),
('SC', 'South Carolina'),
('SD', 'South Dakota'),
('TN', 'Tennessee'),
('TX', 'Texas'),
('UT', 'Utah'),
('VT', 'Vermont'),
('VA', 'Virginia'),
('WA', 'Washington'),
('WV', 'West Virginia'),
('WI', 'Wisconsin'),
('VI', 'Virgin Islands'),
('WY', 'Wyoming'); 
