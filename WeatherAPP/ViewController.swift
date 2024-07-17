//
//  ViewController.swift
//  WeatherAPP
//
//  Created by 김승희 on 7/12/24.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    // dataSource는 항상 리스트 타입
    private var dataSource = [ForecastWeather]()
    
    // URLQueryItem은 String으로 넣어줘야 함
    private let urlQueryItems: [URLQueryItem] = [
        URLQueryItem(name: "lat", value: "37.5"),
        URLQueryItem(name: "lon", value: "126.9"),
        URLQueryItem(name: "appid", value: Bundle.main.infoDictionary?["WEATHER_API"] as? String),
        URLQueryItem(name: "units", value: "metric")
    ]

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "서울특별시"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 30)
        return label
    }()
    
    private let tempLabel: UILabel = {
        let label = UILabel()
        label.text = "20도"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 50)
        return label
    }()

    private let tempMinLabel: UILabel = {
        let label = UILabel()
        label.text = "20도"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()
    
    private let tempMaxLabel: UILabel = {
        let label = UILabel()
        label.text = "20도"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()
    
    private let tempStackView: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .horizontal
        stackview.spacing = 20
        stackview.distribution = .fillEqually
        return stackview
    }()
    
    private let imageView: UIImageView = {
        let imageview = UIImageView()
        imageview.contentMode = .scaleAspectFit
        imageview.backgroundColor = .black
        return imageview
    }()
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.backgroundColor = .black
        tableview.delegate = self
        tableview.dataSource = self
        
        // 테이블뷰에 테이블뷰셀 등록
        tableview.register(TableViewCell.self, forCellReuseIdentifier: TableViewCell.id)
        
        return tableview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchCurrentWeatherData()
        fetchForecastData()
    }
    
    //서버 데이터 불러오는 일반적인 메서드
    // Decodable을 채택하는 어떤 타입도 T? 안에 들어갈 수 있다
    // 가져와야 할 API가 2가지인데, 어느 타입에서라도 일반적으로 재사용할 수 있게 제네릭을 사용함
    // escaping 클로저: 메서드가 끝이 나더라도 탈출해서 돌아다니다 언제든지 실행될 수 있다는 뜻
    private func fetchData <T: Decodable>(url: URL, completion: @escaping (T?) -> Void) {
        let session = URLSession(configuration: .default)
        session.dataTask(with: URLRequest(url: url)) { data, response, error in
            guard let data, error == nil else {
                print("데이터 로드 실패")
                completion(nil)
                return
            }
            // http status 코드 성공 범위는 200번대
            // HTTPURLResponse 안에 http status code를 깔 수 있기 때문에 타입 캐스팅
            let successRange = 200..<300
            if let response = response as? HTTPURLResponse, successRange.contains(response.statusCode) {
                guard let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
                    print("Json 디코딩 실패")
                    completion(nil)
                    return
                }
                completion(decodedData)
            } else {
                print("응답 오류")
                completion(nil)
            }
        }.resume()
    }
    
    private func fetchCurrentWeatherData() {
        var urlComponents = URLComponents(string:"https://api.openweathermap.org/data/2.5/weather")
        urlComponents?.queryItems = self.urlQueryItems
        
        guard let url = urlComponents?.url else {
            print("잘못된 URL")
            return
        }
        
        // 이렇게 타입 명시해주면 위의 T들이 CurrentWeatherResult로 인식
        // 강한 참조 순환 방지 위해 weak self 사용
        // 서버에서 불러오는 데이터는 백그라운드 스레드에서 처리 - UI를 그리는 작업은 메인스레드에서 처리, 따라서 서버 데이터는 백그라운드스레드
        fetchData(url: url) { [weak self] (result: CurrentWeatherResult?) in
            guard let self, let result else {return}
            
            // 현재 백그라운드스레드에서 작업중, 하지만 UI는 반드시 메인스레드에서 작업되어야 하기에 이를 명시해줌
            DispatchQueue.main.async {
                self.tempLabel.text = "\(Int(result.main.temp))°C"
                self.tempMinLabel.text = "최저: \(Int(result.main.tempMin))°C"
                self.tempMaxLabel.text = "최고: \(Int(result.main.tempMax))°C"
            }
            
            guard let imageUrl = URL(string: "https://openweathermap.org/img/wn/\(result.weather[0].icon)@2x.png") else {
                return
            }
            
            // image 로드 작업도 백그라운드스레드 작업, 따라서 UI작업 main스레드 작업 명시
            if let data = try? Data(contentsOf: imageUrl) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                    }
                }
            }
        }
    }
    
    // 서버에서 5일간 날씨 예보 데이터를 불러오는 메서드
    private func fetchForecastData() {
        var urlComponents = URLComponents(string: "https://api.openweathermap.org/data/2.5/forecast")
        urlComponents?.queryItems = self.urlQueryItems
        
        guard let url = urlComponents?.url else {
            print("잘못된 URL")
            return
        }
        
        fetchData(url: url) { [weak self] (result: ForecastWeatherResult?) in
            guard let self, let result else { return }
            // 콘솔에 데이터 잘 불러왔는지 찍어보기
            for forecastWeather in result.list {
                print("\(forecastWeather.main) \(forecastWeather.dtTxt)")
            }
            
            DispatchQueue.main.async {
                self.dataSource = result.list
                self.tableView.reloadData()
            }
        }
    }

    private func configureUI() {
        view.backgroundColor = .black
        [titleLabel, tempLabel, tempStackView, imageView, tableView].forEach{ view.addSubview($0) }
        
        [tempMinLabel, tempMaxLabel].forEach{ tempStackView.addArrangedSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(120)
        }
        
        tempLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        
        tempStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(tempLabel.snp.bottom).offset(10)
        }
        
        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(160)
            $0.top.equalTo(tempStackView.snp.bottom).offset(20)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(50)
        }
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        40
    }
    
}

extension ViewController: UITableViewDataSource {
    
    //tableView의 indexPath 마다 테이블뷰 셀을 지정
    // indexPath = 테이블뷰의 행과 섹션을 의미
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.id) as? TableViewCell else {
            return UITableViewCell()
        }
        cell.configureCell(forecastWeather: dataSource[indexPath.row])
        return cell
    }
}
