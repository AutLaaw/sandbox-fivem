import React, { useEffect, useState } from 'react';
import {
    List,
    ListItem,
    ListItemText,
    Grid,
    Alert,
    Button,
    Avatar,
    TextField,
    InputAdornment,
    IconButton,
    ButtonGroup,
    FormGroup,
    FormControlLabel,
    Switch,
    Chip,
    Typography,
    Slider,
} from '@mui/material';
import { makeStyles } from '@mui/styles';
import { toast } from 'react-toastify';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { Link, useNavigate, useLocation } from 'react-router-dom';

import qs from 'qs';

import { Loader, Modal } from '../../components';
import Nui from '../../util/Nui';
import { useSelector } from 'react-redux';

import { usePermissions } from '../../hooks';

const VehicleIcons = ['car-side', 'ship', 'plane-engines'];

import { ReportTypes } from '../../data';

const useStyles = makeStyles((theme) => ({
    nWrapper: {
        padding: '10px 5px 10px 5px',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignContent: 'center',
        textAlign: 'center',
        fontSize: 22,
    },
    wrapper: {
        padding: '10px 5px 10px 5px',
        height: '100%',
        overflow: 'hidden',
    },
    nWrapperIcon: {
        opacity: '50%',
        color: theme.palette.primary.main,
        fontSize: 80,
        marginBottom: 20,
    },
    mainInfos: {
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignContent: 'center',
    },
    mugshot: {
        margin: 'auto',
        //marginBottom: 25,
        height: 150,
        width: 150,
        border: `3px solid ${theme.palette.primary.main}8a`,
    },
    link: {
        color: theme.palette.text.alt,
        transition: 'color ease-in 0.15s',
        '&:hover': {
            color: theme.palette.primary.main,
        },
        '&:not(:last-of-type)::after': {
            color: theme.palette.text.main,
            content: '", "',
        },
    },
    item: {
        margin: 4,
        transition: 'background ease-in 0.15s',
        border: `1px solid ${theme.palette.border.divider}`,
        margin: 7.5,
        transition: 'filter ease-in 0.15s',
        '&:hover': {
            filter: 'brightness(0.8)',
            cursor: 'pointer',
        },
    },
    jobChip: {
        backgroundColor: '#00497d',
    },
    vehicleChip: {
        backgroundColor: '#81449c',
    },
    charge: {
        margin: 4,
        '&.type-1': {
            backgroundColor: theme.palette.info.main,
        },
        '&.type-2': {
            backgroundColor: theme.palette.warning.main,
        },
        '&.type-3': {
            backgroundColor: theme.palette.error.main,
        },
    },
    editorField: {
        marginTop: 10,
    },
    items: {
        maxHeight: '95%',
        height: '95%',
        overflowY: 'auto',
        overflowX: 'hidden',
    },
    itemWrapper: {
        padding: '5px 2.5px 5px 5px',
        borderBottom: `1px solid ${theme.palette.border.divider}`,
        '&:first-of-type': {
            borderTop: `1px solid ${theme.palette.border.divider}`,
        },
    },
}));

const getLicenceStatus = (data) => {
    let status = 'Active';
    if (data?.Suspended) {
        status = 'Suspended';
    }

    if (data?.Points && data?.Points > 0) {
        status += ` - ${data?.Points} Points`;
    }

    return status;
};

export default ({ }) => {
    const classes = useStyles();
    const history = useNavigate();
    const location = useLocation();
    const hasPermission = usePermissions();
    const myJob = useSelector((state) => state.app.govJob);
    const charges = useSelector((state) => state.data.data.charges);

    let qry = qs.parse(location.search.slice(1));
    const personId = qry.person;

    const govJobs = useSelector((state) => state.data.data.governmentJobs);

    const [err, setErr] = useState(false);
    const [loading, setLoading] = useState(false);
    const [person, setPerson] = useState(null);
    const [prevConvictions, setPrevConvictions] = useState(null);
    const [parole, setParole] = useState(null);

    const [editFlags, setEditFlags] = useState(false);
    const [editLawyer, setEditLawyer] = useState(false);
    const [editSuspended, setEditSuspended] = useState(false);
    const [clearRecord, setClearRecord] = useState(false);
    const [mugshot, setMugshot] = useState(false);
    const [pendingMugshot, setPendingMugshot] = useState('');

    const [editLicensePoints, setEditLicensePoints] = useState(false);

    const [viewingLogs, setViewingLogs] = useState(false);

    const isGovernment = (jobs) => {
        if (jobs && jobs?.length > 0 && govJobs?.length > 0) {
            return jobs?.find((j) => govJobs.includes(j.Id));
        }
    };

    const onCreate = () => {
        history(`/reports?mode=create&addSuspect=${person.data.SID}`);
    };

    const onSearch = () => {
        history(`/reports?search=suspect: ${person.data.SID}`);
    };

    const onEditMugshot = () => {
        setPendingMugshot(person.data.Mugshot);
        setMugshot(true);
    };

    const onMugshotSave = async (e) => {
        e.preventDefault();

        try {
            let res = await (
                await Nui.send('Update', {
                    type: 'person',
                    SID: person.data.SID,
                    Key: 'Mugshot',
                    Data: pendingMugshot,
                })
            ).json();
            if (res) {
                setPerson({
                    ...person,
                    data: {
                        ...person.data,
                        Mugshot: pendingMugshot,
                    },
                });
                setMugshot(false);
                setPendingMugshot('');
                toast.success('Mugshot Updated');
            }
        } catch (err) {
            console.log(err);
        }
    };

    const onFlagsSave = async (e) => {
        e.preventDefault();

        let t = {
            Violent: e.target.violent.checked,
            Gang: e.target.gang.value,
        };
        try {
            let res = await (
                await Nui.send('Update', {
                    type: 'person',
                    SID: person.data.SID,
                    Key: 'Flags',
                    Data: t,
                })
            ).json();

            if (res) {
                setPerson({
                    ...person,
                    data: {
                        ...person.data,
                        Flags: t,
                    },
                });
                setEditFlags(false);
                toast.success('Flags Updated');
            }
        } catch (err) {
            console.log(err);
            setEditFlags(false);
        }
    };

    const onLawyerSave = async (e) => {
        e.preventDefault();

        try {
            let res = await (
                await Nui.send('Update', {
                    type: 'person',
                    SID: person.data.SID,
                    Key: 'Attorney',
                    Data: e.target.attorney.checked,
                })
            ).json();

            if (res) {
                setPerson({
                    ...person,
                    data: {
                        ...person.data,
                        Attorney: e.target.attorney.checked,
                    },
                });
                setEditLawyer(false);
                toast.success('Certification Updated');
            }
        } catch (err) {
            console.log(err);
            setEditLawyer(false);
        }
    };

    const onSuspensionSave = async (e) => {
        e.preventDefault();

        let unSuspending = {};

        Object.keys(person.data.Licenses).map((license) => {
            const licenseData = person.data.Licenses[license];
            if (licenseData?.Suspended && !e.target[license].checked) {
                unSuspending[license] = true;
            }
        })

        try {
            let res = await (
                await Nui.send('RevokeSuspension', {
                    SID: person.data.SID,
                    unsuspend: unSuspending,
                })
            ).json();

            if (res) {
                setPerson({
                    ...person,
                    data: {
                        ...person.data,
                        Licenses: res,
                    },
                });
                setEditSuspended(false);
                toast.success('License Suspensions Updated');
            } else {
                setEditSuspended(false);
                toast.error('Failed to Update License Suspensions');
            }
        } catch (err) {
            console.log(err);
            setEditSuspended(false);
        }
    };

    const onRemoveLicensePoints = async (e) => {
        e.preventDefault();

        try {
            const newPoints = person.data.Licenses.Drivers.Points - e.target.points.value;

            console.log("Set Points to ", newPoints)

            if (newPoints >= 0) {
                let res = await (
                    await Nui.send('RemovePoints', {
                        SID: person.data.SID,
                        newPoints,
                    })
                ).json();

                if (res) {
                    setPerson({
                        ...person,
                        data: {
                            ...person.data,
                            Licenses: {
                                ...person.data.Licenses,
                                Drivers: {
                                    ...person.data.Licenses.Drivers,
                                    Points: newPoints,
                                }
                            },
                        },
                    });
                    setEditLicensePoints(false);
                    toast.success('Drivers License Points Updated');
                } else {
                    setEditLicensePoints(false);
                    toast.error('Failed to Update Drivers License Points');
                }
            } else {
                setEditLicensePoints(false);
                toast.error('Failed to Update Drivers License Points');
            }
        } catch (err) {
            console.log(err);
            setEditLicensePoints(false);
        }
    };

    const onRecordClear = async (e) => {
        e.preventDefault();

        if (!e.target.confirm.checked) {
            setClearRecord(false);
            return toast.error('Failed to Clear Record');
        }

        try {
            let res = await (
                await Nui.send('ClearRecord', {
                    SID: person.data.SID,
                })
            ).json();

            if (res) {
                setPrevConvictions(null);

                setClearRecord(false);
                toast.success('Criminal Record Cleared');
            } else {
                setClearRecord(false);
                toast.error('Failed to Clear Record');
            }
        } catch (err) {
            console.log(err);
            setClearRecord(false);
        }
    };

    const onVehicleClick = (VIN) => {
        history(`/vehicles?vehicle=${VIN}`);
    };

    useEffect(() => {
        const fetch = async (sid) => {
            setLoading(true);
            try {
                let res = await (
                    await Nui.send('View', {
                        type: 'person',
                        id: sid,
                    })
                ).json();

                if (res) {
                    setPerson(res);
                    if (res?.convictions && res?.convictions.length > 0) {
                        const chargeList = [];

                        res.convictions.forEach((charge) => {
                            const existingCharge = chargeList.findIndex((c) => c.id == charge.id);
                            if (existingCharge > -1) {
                                const existingData = chargeList[existingCharge];

                                chargeList.splice(existingCharge, 1, {
                                    ...charge,
                                    count: charge.count + existingData.count,
                                });
                            } else chargeList.push(charge);
                        });

                        setPrevConvictions(
                            chargeList
                                .filter(c => charges.find(ch => ch.id === c.id))
                                .map(c => ({
                                    ...charges.find(ch => ch.id == c.id),
                                    id: c.id,
                                    count: c.count,
                                }))
                        );
                    } else setPrevConvictions(null);

                    if (res?.parole && res?.parole?.end > Date.now()) {
                        const monthsRemaining = Math.ceil(moment.duration(res?.parole?.end - Date.now(), 'ms').asMinutes());
                        setParole(monthsRemaining);
                    } else setParole(null);
                } else toast.error('Unable to Load');
            } catch (err) {
                console.log(err);
                toast.error('Unable to Load');
                //setErr(true);

                setPerson({
                    data: {
                        _id: '6088b90c93a7b379e0c83ef2',
                        SID: 1,
                        User: '606c22a749c1c980e8289b35',
                        Phone: '121-195-9016',
                        Gender: 0,
                        Callsign: 400,
                        Origin: 'United States',
                        First: 'Testy',
                        Last: 'McTest',
                        DOB: '1991-01-01T07:59:59.000Z',
                        Licenses: {
                            Drivers: {
                                Active: true,
                                Points: 2,
                            },
                            Weapons: {
                                Active: true,
                            },
                        },
                        Qualifications: ['fto'],
                        Jobs: [
                            {
                                Workplace: {
                                    Id: 'lspd',
                                    Name: 'Los Santos Police Department',
                                },
                                Name: 'Police',
                                Grade: {
                                    Id: 'chief',
                                    Name: 'Chief',
                                },
                                Id: 'police',
                            },
                        ]
                    },
                    vehicles: []
                });

                setPrevConvictions(Array(200).fill({
                    count: 1,
                    id: 1,
                    title: 'Testing this',
                }));
            }
            setLoading(false);
        };

        if (personId) {
            fetch(personId);
        }
    }, [personId]);

    const incidentReport = ReportTypes.find((rt) => rt.value == 0);
    const canCreateReport = hasPermission(incidentReport?.requiredCreatePermission, false);
    const canViewVehicles = myJob?.Id == "police" || (myJob?.Id == "government" && myJob?.Workplace?.Id != "publicdefenders")

    if (loading || !person) {
        return (
            <div className={classes.nWrapper}>
                {loading ? (
                    <Loader text="Loading" />
                ) : (
                    <>
                        <FontAwesomeIcon className={classes.nWrapperIcon} icon={['fas', 'person']} />
                        <div>No Person Selected</div>
                    </>
                )}
            </div>
        );
    };

    return (
        <div className={classes.wrapper}>
            <Grid container spacing={2} style={{ height: '100%', paddingBottom: 10, overflowY: 'auto', overflowX: 'hidden' }} justifyContent="center" alignContent="flex-start">
                {(myJob?.Id == "police" || myJob?.Id == "government") && <Grid item xs={12}>
                    <ButtonGroup fullWidth>
                        {myJob?.Id == "police" && <Button onClick={() => setEditFlags(true)}>Flags</Button>}
                        {myJob?.Id == "police" && <Button disabled={isGovernment(person.data?.Jobs)} onClick={onEditMugshot}>
                            Mugshot
                        </Button>}
                        <Button onClick={onSearch}>Related Incident Reports</Button>
                        {canCreateReport && <Button onClick={onCreate}>Create Incident</Button>}
                        {hasPermission('BAR_CERTIFICATIONS') && (
                            <Button fullWidth onClick={() => setEditLawyer(true)}>
                                Certs
                            </Button>
                        )}
                        {hasPermission('REVOKE_LICENSE_SUSPENSIONS') && (
                            <Button fullWidth onClick={() => setEditSuspended(true)}>
                                Suspensions
                            </Button>
                        )}
                        {hasPermission('REVOKE_LICENSE_SUSPENSIONS') && (
                            <Button fullWidth disabled={person?.data?.Licenses?.Drivers?.Points <= 0} onClick={() => setEditLicensePoints(true)}>
                                Points
                            </Button>
                        )}
                        {hasPermission('EXPUNGEMENT') && (
                            <Button fullWidth onClick={() => setClearRecord(true)}>
                                Expunge
                            </Button>
                        )}
                        {hasPermission('system-admin') && (
                            <Button fullWidth onClick={() => setViewingLogs(true)}>
                                Logs
                            </Button>
                        )}
                    </ButtonGroup>
                </Grid>}
                {parole && (
                    <Grid item xs={12}>
                        <Alert variant="filled" severity="info">
                            Has {parole} Month(s) of Parole Remaining
                        </Alert>
                    </Grid>
                )}
                <Grid item xs={6}>
                    <Grid container spacing={1}>
                        <Grid item xs={5} className={classes.mainInfos}>
                            <Avatar
                                className={classes.mugshot}
                                src={person.data.Mugshot ? person.data.Mugshot : null}
                                alt={person.data.First}
                            />
                        </Grid>
                        <Grid item xs={7} className={classes.mainInfos}>
                            <Typography variant="h4">
                                {`${person.data.First} ${person.data.Last}`}
                            </Typography>
                            <Typography variant="h6">
                                State ID: {person.data.SID}
                            </Typography>
                            <Typography variant="h6">
                                Sex: {person.data.Gender ? 'Female' : 'Male'}
                            </Typography>
                            <Typography variant="h6">
                                DOB: {moment(person.data.DOB).format('LL')}
                            </Typography>
                        </Grid>
                    </Grid>

                    <List>
                        {parole && (
                            <ListItem>
                                <ListItemText primary="Remaining Parole" secondary={`${parole} Month(s)`} />
                            </ListItem>
                        )}
                        {person.data.Attorney && (
                            <ListItem>
                                <ListItemText primary="Bar Certified Attorney" secondary="Yes" />
                            </ListItem>
                        )}
                        {canViewVehicles && person.vehicles.length > 0 && (
                            <ListItem>
                                <ListItemText primary="Owned Vehicles" />
                            </ListItem>
                        )}
                        {canViewVehicles && person.vehicles.map((v) => {
                            return (
                                <Chip
                                    key={v.VIN}
                                    className={`${classes.item} ${classes.vehicleChip}`}
                                    icon={
                                        <FontAwesomeIcon
                                            icon={['fas', VehicleIcons[v.Type] ?? 'car-mirrors']}
                                        />
                                    }
                                    label={`${v.Make} ${v.Model} [${v.RegisteredPlate}]`}
                                    onClick={() => onVehicleClick(v.VIN)}
                                />
                            );
                        })}
                        <ListItem>
                            <ListItemText
                                primary="Violent"
                                secondary={person.data.Flags?.Violent ? 'Yes' : 'No'}
                            />
                        </ListItem>
                        <ListItem>
                            <ListItemText
                                primary="Gang Affiliation"
                                secondary={(person.data.Flags?.Gang && person.data.Flags?.Gang?.length > 0) ? person.data.Flags?.Gang : 'None'}
                            />
                        </ListItem>
                    </List>
                </Grid>
                <Grid item xs={6}>
                    {isGovernment(person.data?.Jobs) && (
                        <>
                            <ListItem>
                                <ListItemText primary="Government Employee" />
                            </ListItem>
                            <Chip
                                className={`${classes.item} ${classes.jobChip}`}
                                label={`${isGovernment(person.data?.Jobs)?.Workplace?.Name} - ${isGovernment(person.data?.Jobs)?.Grade?.Name
                                    }`}
                                icon={null}
                            />
                        </>
                    )}
                    {person.data?.Jobs?.filter((j) => !govJobs.includes(j.Id) && !j.Hidden).length > 0 && <ListItem>
                        <ListItemText primary="Employment Information" />
                    </ListItem>}
                    {person.data?.Jobs?.filter((j) => !govJobs.includes(j.Id) && !j.Hidden).map((j) => {
                        return (
                            <Chip
                                key={j.Id}
                                className={`${classes.item} ${classes.jobChip}`}
                                label={`${j.Workplace?.Name ?? j.Name} - ${j.Grade?.Name ?? 'Employee'}`}
                                icon={
                                    person.ownedBusinesses?.includes(j.Id) ? (
                                        <FontAwesomeIcon icon={['fas', 'crown']} />
                                    ) : null
                                }
                            />
                        );
                    })}
                    <ListItem>
                        <ListItemText primary="Criminal Record" />
                    </ListItem>
                    <List
                        style={{
                            maxHeight: '30vh',
                            //height: '100%',
                            overflowY: 'auto',
                            overflowX: 'hidden',
                        }}
                    >
                        {prevConvictions ? (
                            prevConvictions
                                .sort((a, b) => b.jail + b.fine - (a.jail - a.fine))
                                .map((c, k) => {
                                    return (
                                        <Chip
                                            key={`charge-${k}`}
                                            className={`${classes.charge} type-${c.type}`}
                                            label={`${c.title} x${c.count}`}
                                        />
                                    );
                                })
                        ) : (
                            <ListItem>
                                <Alert severity="info">
                                    {person.data.First} {person.data.Last} Has No Past Convictions 🙂
                                </Alert>
                            </ListItem>
                        )}
                    </List>
                    {person?.data?.Licenses &&
                        Object.keys(person.data.Licenses).map((license) => {
                            const licenseData = person.data.Licenses[license];
                            if (licenseData.Active || licenseData.Suspended) {
                                return (
                                    <ListItem>
                                        <ListItemText
                                            primary={`${license} License`}
                                            secondary={getLicenceStatus(licenseData)}
                                        />
                                    </ListItem>
                                );
                            } else return null;
                        })}
                </Grid>
            </Grid>
            <Modal
                open={mugshot}
                title="Update Mugshot"
                onSubmit={onMugshotSave}
                onClose={() => setMugshot(false)}
            >
                <Avatar className={classes.mugshot} src={pendingMugshot} alt={person.data.First} />
                <TextField
                    fullWidth
                    required
                    variant="standard"
                    name="mugshot"
                    value={pendingMugshot}
                    onChange={(e) => setPendingMugshot(e.target.value)}
                    label="Image URL"
                    InputProps={{
                        endAdornment: (
                            <InputAdornment position="end">
                                {pendingMugshot != '' && (
                                    <IconButton onClick={() => pendingMugshot('')}>
                                        <FontAwesomeIcon icon={['fas', 'xmark']} />
                                    </IconButton>
                                )}
                            </InputAdornment>
                        ),
                    }}
                />
            </Modal>
            <Modal
                open={editFlags}
                title="Update Flags"
                onSubmit={onFlagsSave}
                onClose={() => setEditFlags(false)}
            >
                <FormGroup>
                    <FormControlLabel
                        label="Violent"
                        control={
                            <Switch
                                color="primary"
                                name="violent"
                                defaultChecked={person.data.Flags?.Violent}
                            />
                        }
                    />
                </FormGroup>
                <FormGroup>
                    <TextField
                        className={classes.editorField}
                        name="gang"
                        label="Gang Affiliated"
                        variant="standard"
                        fullWidth
                        defaultValue={typeof (person.data.Flags?.Gang) == 'string' ? person.data.Flags?.Gang : ''}
                    />
                </FormGroup>
            </Modal>
            <Modal
                open={editLawyer}
                title="Update Qualifications"
                onSubmit={onLawyerSave}
                onClose={() => setEditLawyer(false)}
            >
                <FormGroup>
                    <FormControlLabel
                        label="Bar Certified Attorney"
                        control={
                            <Switch color="primary" name="attorney" defaultChecked={person.data.Attorney} />
                        }
                    />
                </FormGroup>
            </Modal>
            <Modal
                open={editSuspended}
                title="License Suspensions"
                onSubmit={onSuspensionSave}
                onClose={() => setEditSuspended(false)}
            >
                <p>Turn off the sliders to revoke a license suspension. This will reset drivers license points.</p>
                <FormGroup>
                    {Object.keys(person.data.Licenses).map((license) => {
                        const licenseData = person.data.Licenses[license];
                        if (licenseData?.Suspended) {
                            return (
                                <FormControlLabel
                                    label={`${license} License`}
                                    control={
                                        <Switch color="primary" name={license} defaultChecked={true} />
                                    }
                                />
                            );
                        } else return null;
                    })}
                </FormGroup>
            </Modal>
            <Modal
                open={editLicensePoints}
                title="Driver License Points"
                onSubmit={onRemoveLicensePoints}
                onClose={() => setEditLicensePoints(false)}
            >
                <p>Remove drivers license points (this will not unsuspend the license)</p>
                <Slider
                    name="points"
                    step={1}
                    marks
                    defaultValue={1}
                    min={1}
                    max={person.data?.Licenses?.Drivers?.Points}
                    valueLabelDisplay="auto"
                />
            </Modal>
            <Modal
                open={clearRecord}
                title="Criminal Record Expungement"
                onSubmit={onRecordClear}
                onClose={() => setClearRecord(false)}
            >
                <p>This will expunge an invidual and clear their criminal record completely.</p>
                <FormGroup>
                    <FormControlLabel
                        label="Confirmation"
                        control={
                            <Switch color="primary" name="confirm" defaultChecked={false} />
                        }
                    />
                </FormGroup>
            </Modal>
            <Modal
                open={viewingLogs}
                title="View System Logs"
                onClose={() => setViewingLogs(false)}
            >
                <List className={classes.items}>
                    {person?.data?.MDTHistory ? person.data.MDTHistory.sort((a, b) => b.Time - a.Time).map(h => {
                        return <ListItem className={classes.itemWrapper}>
                            <ListItemText
                                primary={h.Log}
                                secondary={`${h.Char > - 1 ? `SID ${h.Char}` : 'System'} | ${moment(h.Time).format('lll')}`}
                            />
                        </ListItem>
                    }) : null}
                </List>
            </Modal>
        </div >
    );
};
