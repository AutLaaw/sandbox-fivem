import React, { useEffect, useMemo, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import {
    Grid,
    TextField,
    InputAdornment,
    IconButton,
    Pagination,
    List,
    Button,
    MenuItem,
} from '@mui/material';
import { makeStyles } from '@mui/styles';
import { throttle } from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import { usePermissions, useAlert } from '../../../../../hooks';

import Nui from '../../../../../util/Nui';
import { Loader } from '../../../../../components';

import Item from './components/Property';
import { propertyCategories } from './data';
import SaleForm from './SaleForm';
import ConstructionForm from './ConstructionForm';
import InfoForm from './InfoForm';
import TransferForm from './TransferForm';

const useStyles = makeStyles((theme) => ({
    wrapper: {
        padding: '20px 10px 20px 20px',
        height: '100%',
    },
    search: {
        //height: '10%',
    },
    results: {
        //height: '',
    },
    noResults: {
        margin: '15% 0',
        textAlign: 'center',
        fontSize: 22,
        color: theme.palette.text.main,
    },
    items: {
        maxHeight: '95%',
        height: '95%',
        overflowY: 'auto',
        overflowX: 'hidden',
    },
    searchButton: {
        height: '90%',
        // marginBottom: 10,
    },
}));

const escapeRegex = (string) => {
    return string.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
}

export default ({ onNav }) => {
    const classes = useStyles();
    const dispatch = useDispatch();
    const alert = useAlert();

    const PER_PAGE = 6;

    const [pages, setPages] = useState(1);
    const [page, setPage] = useState(1);
    const [loading, setLoading] = useState(false);
    const [err, setErr] = useState(false);
    const [results, setResults] = useState(Array());
    const [upgrades, setUpgrades] = useState(Array());
    const [filtered, setFiltered] = useState(Array());
    const [searched, setSearched] = useState('');
    const [cat, setCat] = useState('all');

    const [sellingOpen, setSellingOpen] = useState(false);
    const [selling, setSelling] = useState(null);

    const [editingOpen, setEditingOpen] = useState(false);
    const [editingData, setEditingData] = useState(null);

    const [viewingInfo, setViewingInfo] = useState(false);
    const [transfer, setTransfer] = useState(false);

    useEffect(() => {
        fetch();
    }, []);

    useEffect(() => {
        setFiltered(results.filter((r) => {
            return (
                (r.label.toLowerCase().includes(searched.toLowerCase())) ||
                (r.owner && `${r.owner?.First} ${r.owner?.Last}`.toLowerCase().includes(searched.toLowerCase())) ||
                (r.owner && (r.owner?.SID == parseInt(searched))) ||
                (searched == "")
            ) && (r?.type == cat || cat == 'all')
        }));
    }, [results, searched, cat]);

    useEffect(() => {
        setPages(Math.ceil(filtered?.length / PER_PAGE));
    }, [filtered]);

    const fetch = async () => {
        setLoading(true);
        setPage(1);

        try {
            let res = await (
                await Nui.send('Dyn8SearchProperties', {})
            ).json();

            if (res?.properties) {
                setResults(res.properties);
                setUpgrades(res.upgrades);
                setCat('all');
            } else throw res;
            setLoading(false);
        } catch (err) {
            console.log(err);
            setErr(true);

            // setResults({
            //     properties: [{
            //         "_id": "62518e75841f5a4cb4eb3b41",
            //         "label": "Lovely House",
            //         "sold": false,
            //         "type": "house",
            //         "location": {
            //           "front": {
            //             "y": 315.94287109375,
            //             "z": 81.89814453125,
            //             "x": -689.2219848632812,
            //             "h": 175.74803161621094
            //           }
            //         },
            //         "interior": 2,
            //         "price": 1
            //       },{
            //         "_id": "2",
            //         "location": {
            //           "front": {
            //             "y": 303.27032470703125,
            //             "x": -727.89892578125,
            //             "h": 0,
            //             "z": 83.667431640625
            //           },
            //           "garage": {
            //             "y": 295.3186950683594,
            //             "z": 84.800048828125,
            //             "x": -729.1780395507812,
            //             "h": 181.41732788085938
            //           }
            //         },
            //         "sold": true,
            //         "type": "house",
            //         "price": 10,
            //         "label": "John's House",
            //         "interior": 40,
            //         "keys": {
            //           "621aa10ecf57fe19e42a4ca7": {
            //             "Last": "Man",
            //             "SID": 1,
            //             "Char": "621aa10ecf57fe19e42a4ca7",
            //             "First": "Silly",
            //             "Owner": true
            //           }
            //         }
            //       },{
            //         "_id": "3",
            //         "location": {
            //           "front": {
            //             "h": 102.04724884033203,
            //             "x": 394.3648376464844,
            //             "y": -816.5406494140625,
            //             "z": 28.0799072265625
            //           }
            //         },
            //         "interior": 69,
            //         "type": "office",
            //         "label": "lol",
            //         "sold": true,
            //         "price": 1,
            //         "keys": {
            //           "621aa10ecf57fe19e42a4ca7": {
            //             "Owner": true,
            //             "Last": "Man",
            //             "SID": 1,
            //             "Char": "621aa10ecf57fe19e42a4ca7",
            //             "First": "Silly"
            //           }
            //         }
            //       },{
            //         "_id": "4",
            //         "sold": false,
            //         "location": {
            //           "front": {
            //             "z": 81.89814453125,
            //             "y": 316.1406555175781,
            //             "x": -689.076904296875,
            //             "h": 0
            //           }
            //         },
            //         "interior": 3,
            //         "label": "This is a really long property label",
            //         "type": "house",
            //         "price": 100
            //       },{
            //         "_id": "5",
            //         "sold": false,
            //         "location": {
            //           "front": {
            //             "z": 81.89814453125,
            //             "y": 316.1406555175781,
            //             "x": -689.076904296875,
            //             "h": 0
            //           }
            //         },
            //         "interior": 4,
            //         "label": "This is a really really long property label that should probably never exist",
            //         "type": "house",
            //         "price": 1
            //     }],
            // });

            setLoading(false);
        }
    };

    const onSearchChange = (e) => {
        setSearched(e.target.value);
    };

    const onClear = () => {
        setSearched('');
    };

    const onPagi = (e, p) => {
        setPage(p);
    };

    const sellProperty = (property) => {
        setSelling(property);
    };

    const completeSale = async (data) => {
        setSellingOpen(false);
        setLoading(true);

        try {
            let res = await (
                await Nui.send('Dyn8StartSale', {
                    ...data,
                    property: selling._id,
                })
            ).json();

            if (res && res.success) {
                alert(res?.message ?? 'Success');
                setSelling(null);

                fetch();
            } else {
                alert(res?.message ?? 'Error Initiating Sale');
            };
            setLoading(false);
            setSellingOpen(false);
        } catch (err) {
            console.log(err);
            alert('Error Initiating Sale');

            setLoading(false);
            setSellingOpen(false);
        }
    };

    const completeTransfer = async (data) => {
        setTransfer(false);
        setLoading(true);

        try {
            let res = await (
                await Nui.send('Dyn8StartTransfer', {
                    ...data,
                    property: editingData._id,
                })
            ).json();

            if (res && res.success) {
                alert(res?.message ?? 'Success');
                fetch();
            } else {
                alert(res?.message ?? 'Error Initiating Transfer');

            };
            setLoading(false);
            setTransfer(false);
        } catch (err) {
            console.log(err);
            alert('Error Initiating Transfer');
            setLoading(false);
            setTransfer(false);
        }
    };

    const toggleBlips = async (data) => {
        try {
            let res = await (
                await Nui.send('Dyn8ToggleBlips', {})
            ).json();
        } catch (err) {
            console.log(err);
        }
    };

    return (
        <div className={classes.wrapper}>
            <div className={classes.search}>
                <Grid container spacing={1}>
                    <Grid item xs={3}>
                        <TextField
                            select
                            fullWidth
                            label="Category"
                            name="type"
                            className={classes.editorField}
                            value={cat}
                            onChange={(e) => setCat(e.target.value)}
                        >
                            {propertyCategories.map(option => (
                                <MenuItem key={option.value} value={option.value}>
                                    {option.label}
                                </MenuItem>
                            ))}
                        </TextField>
                    </Grid>
                    <Grid item xs={7}>
                        <TextField
                            fullWidth
                            variant="outlined"
                            name="search"
                            value={searched}
                            onChange={onSearchChange}
                            error={err}
                            helperText={err ? 'Error Performing Search' : null}
                            label="Search"
                            InputProps={{
                                endAdornment: (
                                    <InputAdornment position="end">
                                        {searched != '' && (
                                            <IconButton
                                                type="button"
                                                onClick={onClear}
                                            >
                                                <FontAwesomeIcon
                                                    icon={['fas', 'xmark']}
                                                />
                                            </IconButton>
                                        )}
                                    </InputAdornment>
                                ),
                            }}
                        />
                    </Grid>
                    <Grid item xs={2}>
                        <Button
                            variant="outlined"
                            fullWidth
                            style={{ height: '100%' }}
                            onClick={toggleBlips}
                        >
                            Toggle Blips
                        </Button>
                    </Grid>
                </Grid>
            </div>
            <div className={classes.results}>
                {loading ? (
                    <Loader text="Loading" />
                ) : filtered?.length > 0 ? (
                    <>
                        <List className={classes.items}>
                            {filtered
                                .sort((a, b) => a?.price - b?.price)
                                .sort((a, b) => Number(a.sold) - Number(b.sold))
                                .slice((page - 1) * PER_PAGE, page * PER_PAGE)
                                .map((result) => {
                                    return (
                                        <Item
                                            key={result._id}
                                            property={result}
                                            upgradeData={upgrades}
                                            onClick={() => {
                                                setSellingOpen(true);
                                                sellProperty(result);
                                            }}
                                            onSecondaryClick={() => {
                                                setEditingData(result);
                                                setEditingOpen(true);
                                            }}
                                            onViewInfoClick={() => {
                                                setEditingData(result);
                                                setViewingInfo(true);
                                            }}
                                            onTransfer={() => {
                                                setEditingData(result);
                                                setTransfer(true);
                                            }}
                                        />
                                    );
                                })}
                        </List>
                        {pages > 1 && (
                            <Pagination
                                variant="outlined"
                                shape="rounded"
                                color="primary"
                                page={page}
                                count={pages}
                                onChange={onPagi}
                            />
                        )}
                    </>
                ) : <p className={classes.noResults}>No Results Found</p>}
            </div>
            <SaleForm
                open={sellingOpen}
                property={selling}
                onClose={() => setSellingOpen(false)}
                onSubmit={completeSale}
                upgradeData={upgrades}
                interest={15}
            />
            <ConstructionForm
                open={Boolean(editingOpen)}
                property={editingData}
                onClose={() => setEditingOpen(false)}
            />
            <InfoForm
                open={Boolean(viewingInfo)}
                property={editingData}
                upgradeData={upgrades}
                onClose={() => setViewingInfo(false)}
            />
            <TransferForm
                open={Boolean(transfer)}
                property={editingData}
                upgradeData={upgrades}
                onClose={() => setTransfer(false)}
                onSubmit={completeTransfer}
            />
        </div>
    );
};
