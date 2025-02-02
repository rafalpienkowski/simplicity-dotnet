import http from 'k6/http';
import { check } from 'k6';
import { SharedArray } from 'k6/data';
import { Counter } from 'k6/metrics';

const status_200 = new Counter('status_200');
const status_400 = new Counter('status_400');

// Load seat data from the JSON file
const seatsData = new SharedArray('seats', function() {
    return JSON.parse(open('./seats.json'));
});

function getRandomAvailableSeats(seats) {
    let i = Math.floor(Math.random() * seats.length);
    return [seats[i]];
}

export const options = {
    stages: [
        { duration: '5s', target: 10 },
        { duration: '20s', target: 100 },
        { duration: '5s', target: 0 },
    ],
};

export default function() {

    let selectedSeats = getRandomAvailableSeats(seatsData);

    if (selectedSeats.length > 0) {
        let payload = {
            seats: selectedSeats.map(seat => ({
                seat_id: seat.seat_Id,
                last_changed: seat.last_Changed
            }))
        };

        let params = {
            headers: {
                'Content-Type': 'application/json'
            }
        };

        let postRes = http.post('http://localhost:8080/tickets', JSON.stringify(payload), params);

        check(postRes, {
            'Reservation request succeeded': (r) => r.status == 200 || r.status == 400,
        });

        switch (postRes.status) {
            case 200:
                status_200.add(1);
                break;
            case 400:
                status_400.add(1);
                break;
        }

    } else {
        console.log('No available seats to reserve.');
    }
}

