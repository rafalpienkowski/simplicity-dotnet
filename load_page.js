import http from 'k6/http';
import { check } from 'k6';

export const options = {
    stages: [
        { duration: '5s', target: 15 },
        { duration: '20s', target: 100 },
        { duration: '5s', target: 0 },
    ],
};

export default function() {

    let getReq = http.get('http://localhost:5000/tickets/events/3/sectors/A');

    check(getReq, {
        'Reservation request succeeded': (r) => r.status == 200,
    });

}

