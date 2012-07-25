/****************************************************************************
 **
 ** Copyright (C) 2012 Aurindam Jana.
 ** All rights reserved.
 ** Contact: mail@aurindamjana.in
 **
 ** This file is part of the SQLiteExample.
 **
 ** Hangman is free software: you can redistribute it and/or modify
 ** it under the terms of the GNU General Public License as published by
 ** the Free Software Foundation, either version 3 of the License, or
 ** (at your option) any later version.
 **
 ** Hangman is distributed in the hope that it will be useful,
 ** but WITHOUT ANY WARRANTY; without even the implied warranty of
 ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ** GNU General Public License for more details.
 **
 ** You should have received a copy of the GNU General Public License
 ** along with Hangman.  If not, see <http://www.gnu.org/licenses/>.
 **
 ****************************************************************************/
//  RootViewController.m
//  SQLiteExample
//

#import "RootViewController.h"
#import "/usr/include/sqlite3.h"

@interface RootViewController ()

- (NSString *)contactDbPath;
- (void)saveContactName:(NSString *)name number:(NSString *)number;
- (NSString *)getContactNameForNumber:(NSString *)number;
- (NSString *)getContactNumberForName:(NSString *)name;

@end

@implementation RootViewController

enum DataTableViewSections
{
    kContactNameSection = 0,
    kContactNumberSection,
    kControlButtonsSection,
    kTotalNumberOfSections
};

static NSInteger kTextFieldTag = 1;
static NSInteger kLabelTag = 2;

NSString *_contactName;
NSString *_contactNumber;

- (void)dealloc
{
    [super dealloc];
}

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    _contactName = nil;
    _contactNumber = nil;
    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"SQLiteExample";
}


#pragma mark -
#pragma mark Private methods

- (NSString *)contactDbPath
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *documentDirectories = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *dbPath = [[[documentDirectories objectAtIndex:0] path] stringByAppendingPathComponent:@"contacts.db"];

    if ([fileManager fileExistsAtPath:dbPath] == NO) {
        sqlite3 *contactDb = NULL;
        
        if (sqlite3_open([dbPath UTF8String], &contactDb) == SQLITE_OK) {
            char *errMsg;
            const char *sql_stmt = "CREATE TABLE IF NOT EXISTS CONTACTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT UNIQUE, NUMBER TEXT UNIQUE)";
            
            if (sqlite3_exec(contactDb, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
                dbPath = [NSString string];
            
            sqlite3_close(contactDb);
            
        } else {
            dbPath = [NSString string];
        }
    }
    
    return dbPath;
}

- (void)saveContactName:(NSString *)name number:(NSString *)number
{
    sqlite3 *contactDb = NULL;
    
    if (sqlite3_open([[self contactDbPath] UTF8String], &contactDb) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat: @"REPLACE INTO CONTACTS (name, number) VALUES (\"%@\", \"%@\")", name, number];
		sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(contactDb, [insertSQL UTF8String], -1, &statement, NULL) == SQLITE_OK && sqlite3_step(statement) == SQLITE_DONE)
            sqlite3_finalize(statement);
		sqlite3_close(contactDb);
    }
}

- (NSString *)getContactNameForNumber:(NSString *)number
{
    sqlite3 *contactDb = NULL;
    
    NSString *name = nil;
    
    if (sqlite3_open([[self contactDbPath] UTF8String], &contactDb) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT name FROM contacts WHERE number=\"%@\"", number];
		sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(contactDb, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW)
                name = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
        } else {
            NSLog(@"%s", sqlite3_errmsg(contactDb));
        }
        sqlite3_finalize(statement);
		sqlite3_close(contactDb);
    }
    return name;
}

- (NSString *)getContactNumberForName:(NSString *)name
{
    sqlite3 *contactDb = NULL;
    
    NSString *number = nil;
    
    if (sqlite3_open([[self contactDbPath] UTF8String], &contactDb) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat: @"SELECT number FROM contacts WHERE name=\"%@\"", name];
		sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(contactDb, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW)
                number = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
        } else {
            NSLog(@"%s", sqlite3_errmsg(contactDb));
        }
        sqlite3_finalize(statement);
		sqlite3_close(contactDb);
    }
    return number;
}

#pragma mark -
#pragma mark Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kTotalNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    NSInteger rowCount = 1;
    switch (section) {
        case kControlButtonsSection:
            rowCount = 2;
            break;
            
        default:
            break;
    }
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *kContactNameCellIdentifier = @"Name";
	static NSString *kContactNumberCellIdentifier = @"Number";
	static NSString *kControlsCellIdentifier = @"Controls";
    
    UITableViewCell *tableViewCell = nil;
    switch (indexPath.section) {
        case kContactNameSection: {
            tableViewCell = [tableView dequeueReusableCellWithIdentifier:kContactNameCellIdentifier];
            UITextField *textField = nil;
            if (tableViewCell == nil) {
                tableViewCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kContactNameCellIdentifier] autorelease];
                tableViewCell.textLabel.text = NSLocalizedString(@"Name", @"");
                tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                textField = [[[UITextField alloc] initWithFrame:CGRectMake(100, 11, 200, 21)] autorelease];
                textField.backgroundColor = [UIColor clearColor];
                textField.placeholder = NSLocalizedString(@"Enter Name", @"");
                textField.tag = kTextFieldTag;
                
                [tableViewCell.contentView addSubview:textField];
            } else {
                textField = (UITextField *)[tableViewCell viewWithTag:kTextFieldTag];
                if (_contactName != nil)
                    textField.text = _contactName;
            }
            break;
        }
            
        case kContactNumberSection: {
            tableViewCell = [tableView dequeueReusableCellWithIdentifier:kContactNumberCellIdentifier];
            UITextField *textField = nil;
            if (tableViewCell == nil) {
                tableViewCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kContactNumberCellIdentifier] autorelease];
                tableViewCell.textLabel.text = NSLocalizedString(@"Number", @"");
                tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                textField = [[[UITextField alloc] initWithFrame:CGRectMake(100, 11, 200, 21)] autorelease];
                textField.backgroundColor = [UIColor clearColor];
                textField.placeholder = NSLocalizedString(@"Enter Number", @"");
                textField.tag = kTextFieldTag;
                
                [tableViewCell.contentView addSubview:textField];
            } else {
                textField = (UITextField *)[tableViewCell viewWithTag:kTextFieldTag];
                if (_contactNumber != nil)
                    textField.text = _contactNumber;
            }
            break;
        }
            
        case kControlButtonsSection: {
            tableViewCell = [tableView dequeueReusableCellWithIdentifier:kControlsCellIdentifier];
            UILabel *label = nil;
            if (tableViewCell == nil) {
                tableViewCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kControlsCellIdentifier] autorelease];
                
                label = [[[UILabel alloc] initWithFrame:CGRectMake(171, 11, 120, 21)] autorelease];
                label.tag = kLabelTag;
                label.textAlignment = UITextAlignmentRight;
                [tableViewCell.contentView addSubview:label];
                label.backgroundColor = [UIColor clearColor];
               
            } else {
                label = (UILabel *)[tableViewCell.contentView viewWithTag:kLabelTag];
            }

            switch (indexPath.row) {
                case 0: {
                    tableViewCell.textLabel.text = NSLocalizedString(@"Save", @"");
                    label = (UILabel *)[tableViewCell.contentView viewWithTag:kLabelTag];
                    label.text = NSLocalizedString(@"Saved", @"");
                    break;
                }
                case 1: {
                    tableViewCell.textLabel.text = NSLocalizedString(@"Find", @"");
                    label = (UILabel *)[tableViewCell.contentView viewWithTag:kLabelTag];
                    label.text = NSLocalizedString(@"Searching", @"");
                    break;
                }
                    
                default:
                    break;
            }            
            break;
        }
            
        default:
            break;
    }
    return tableViewCell;
}

#pragma mark -
#pragma mark Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *contactNameCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kContactNameSection]];
    UITextField *contactNameTextField = (UITextField *)[contactNameCell viewWithTag:kTextFieldTag];
    NSString *contactName = [contactNameTextField text];
    
    UITableViewCell *contactNumberCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kContactNumberSection]];
    UITextField *contactNumberTextField = (UITextField *)[contactNumberCell viewWithTag:kTextFieldTag];
    NSString *contactNumber = [contactNumberTextField text];
    
    if (indexPath.section == kControlButtonsSection) {
        switch (indexPath.row) {
            case 0: {
                if ([contactName isEqualToString:[NSString string]] == NO && [contactNumber isEqualToString:[NSString string]] == NO)
                [self saveContactName:contactName number:contactNumber];
                break;
            }
        
            case 1: {
                if (contactName != nil && [contactName isEqualToString:[NSString string]] == NO)
                    _contactNumber = [self getContactNumberForName:contactName];
                else if (contactNumber != nil && [contactNumber isEqualToString:[NSString string]] == NO)
                    _contactName = [self getContactNameForNumber:contactNumber];
                [self.tableView reloadData];
                break;
            }
            
            default:
                break;
        }
    }
}

@end
